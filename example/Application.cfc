component 
	output = "false"
	hint = "I define the applications settings and event handlers."
	{

	// Define the application settings.
	this.name = hash( getCurrentTemplatePath() );
	this.applicationTimeout = createTimeSpan( 0, 0, 10, 0 );

	// Get the current directory and the root directory.
	this.appDirectory = getDirectoryFromPath( getCurrentTemplatePath() );
	this.projectDirectory = ( this.appDirectory & "../" );

	// Map the lib directory so we can create our components.
	this.mappings[ "/lib" ] = ( this.projectDirectory & "lib/" );
	this.mappings[ "/jars" ] = ( this.projectDirectory & "jars/" );

	// Set up the custom JAR files for this ColdFusion application. In order to use 
	// Redis, we need to the Jedis JAR and the Apache Commons Pool2 JAR file. Using
	// ColdFusion 10's per-application Java integration, we can make these available
	// in the class paths.
	this.javaSettings = {
		loadPaths: [
			this.mappings[ "/jars" ]
		],
		loadColdFusionClassPath: false,
		reloadOnChange: false
	};


	/**
	* I initialize the application.
	* 
	* @output false 
	*/
	public boolean function onApplicationStart() {

		// Create a JedisPool instance that talks to the locally-hosted Redis server.
		var jedisPool = createObject( "java", "redis.clients.jedis.JedisPool" ).init(
			createObject( "java", "redis.clients.jedis.JedisPoolConfig" ).init(),
			javaCast( "string", "127.0.0.1" )
		);

		// Create a distributed locking service using the single JedisPool instance.
		// --
		// NOTE: While the Redlock algorithm is designed to use multiple servers for
		// fail-over, it works just fine with a single server as well.
		application.locking = new lib.Redlock().createJedisClient( [ jedisPool ] )
			.setPrefix( "locking:" )
		;

		// Create an isolated, single ColdFusion instance using the distributed locking interface.
		// application.locking = new lib.Redlock().createIsolatedClient()
		// 	.setPrefix( "locking:" )
		// ;

		// Create a mock distributed locking service using the given hard-coded get and 
		// delete response values. This is only valuable for testing.
		// application.locking = new lib.Redlock().createTestClient(
		// 	[
		// 		[ false, true ],
		// 		[ true, true ],
		// 		[ true, true ],
		// 		[ false, true ],
		// 		[ false, true ]
		// 	]
		// );

		return( true );

	}


	/**
	* I initialize the request.
	* 
	* @sciprtName I am the script being requested.
	* @output false
	*/
	public boolean function onRequestStart( required string scriptName ) {

		// Check to see if we need to reset the application.
		if ( structKeyExists( url, "init" ) ) {

			applicationStop();
			writeOutput( "Application stopped." );
			abort;

		}

		return( true );

	}


	/**
	* I handle uncaught errors that bubble-up to the root of the application.
	* 
	* @error I am the error object.
	* @eventHandler I am the (optional) event handler that was executing.
	* @output true
	*/
	public void function onError( required any error ) {

		include "./error.cfm";

	}

}