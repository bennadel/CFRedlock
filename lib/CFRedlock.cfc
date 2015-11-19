component
	output = false
	hint = "I provide a means to create a distributed locking service."
	{

	// Set up meaningful defaults.
	DEFAULT_RETRY_DELAY_IN_MILLISECONDS = 200;
	DEFAULT_MAX_RETRY_COUNT = 3;


	/**
	* I create the distributed locking service factory.
	*
	* @output false
	*/
	public any function init() {

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I create a distributed locking service using the given collection of KeyServer
	* instances. The servers are must conform to the KeyServer interface.
	*
	* @keyServers I am the collection of key servers instances to use for locking.
	* @retryDelayInMilliseconds I am the delay to use between retry attempts.
	* @maxRetryCount I am the maximum number of retries to attempt while trying to acquire a lock.
	* @prefix I am the prefix value to prepend to all internal lock names.
	* @output false
	*/
	public any function createClient(
		required array keyServers,
		numeric retryDelayInMilliseconds = DEFAULT_RETRY_DELAY_IN_MILLISECONDS,
		numeric maxRetryCount = DEFAULT_MAX_RETRY_COUNT,
		string prefix = ""
		) {

		var distributedLockClient = new client.DistributedLockClient( arguments.keyServers, arguments.retryDelayInMilliseconds, arguments.maxRetryCount );

		if ( len( arguments.prefix ) ) {

			distributedLockClient.setPrefix( arguments.prefix );

		}

		return( distributedLockClient );

	}


	/**
	* I create a NON-DISTRIBUTED locking service using a single, isolated instance of
	* ColdFusion (ie, this one). The goal of this workflow is to be able to lay the ground
	* work for a distributed locking system without having to have the infrastructure in
	* place. Once done, switching to a distributed system should be seamless.
	*
	* @retryDelayInMilliseconds I am the delay to use between retry attempts.
	* @maxRetryCount I am the maximum number of retries to attempt while trying to acquire a lock.
	* @prefix I am the prefix value to prepend to all internal lock names.
	* @output false
	*/
	public any function createIsolatedClient(
		numeric retryDelayInMilliseconds = DEFAULT_RETRY_DELAY_IN_MILLISECONDS,
		numeric maxRetryCount = DEFAULT_MAX_RETRY_COUNT,
		string prefix = ""
		) {

		var keyServers = [ new server.IsolatedKeyServer() ];

		return( createClient( keyServers, arguments.retryDelayInMilliseconds, arguments.maxRetryCount, arguments.prefix ) );

	}


	/**
	* I create a distributed locking service using the given collection of JedisPool
	* instances.
	*
	* @jedisPools I am the collection of JedisPool instances to use for locking.
	* @retryDelayInMilliseconds I am the delay to use between retry attempts.
	* @maxRetryCount I am the maximum number of retries to attempt while trying to acquire a lock.
	* @prefix I am the prefix value to prepend to all internal lock names.
	* @output false
	*/
	public any function createJedisClient(
		required array jedisPools,
		numeric retryDelayInMilliseconds = DEFAULT_RETRY_DELAY_IN_MILLISECONDS,
		numeric maxRetryCount = DEFAULT_MAX_RETRY_COUNT,
		string prefix = ""
		) {

		var keyServers = [];
		var jedisPool = "";

		for ( jedisPool in arguments.jedisPools ) {

			arrayAppend( keyServers, new server.JedisKeyServer( jedisPool ) );

		}

		return( createClient( keyServers, arguments.retryDelayInMilliseconds, arguments.maxRetryCount, arguments.prefix ) );

	}


	/**
	* I create a distributed locking service using a collection of test servers. Each
	* key server has a hard coded return value for both setting and deleting keys. The
	* test configuration is a two dimension array of set/delete responses:
	*
	* Example:
	* [ [ true, false ], [ true, true ], [ false, false ] ]
	*
	* @testConfiguration I am the testing configuration.
	* @retryDelayInMilliseconds I am the delay to use between retry attempts.
	* @maxRetryCount I am the maximum number of retries to attempt while trying to acquire a lock.
	* @prefix I am the prefix value to prepend to all internal lock names.
	* @output false
	*/
	public any function createTestClient(
		required array testConfiguration,
		numeric retryDelayInMilliseconds = DEFAULT_RETRY_DELAY_IN_MILLISECONDS,
		numeric maxRetryCount = DEFAULT_MAX_RETRY_COUNT,
		string prefix = ""
		) {

		var keyServers = [];
		var config = "";

		for ( var config in arguments.testConfiguration ) {

			var setResponse = config[ 1 ];
			var deleteResponse = config[ 2 ];

			arrayAppend( keyServers, new server.TestKeyServer( setResponse, deleteResponse ) );

		}

		return( createClient( keyServers, arguments.retryDelayInMilliseconds, arguments.maxRetryCount, arguments.prefix ) );

	}

}