component
	extends = "TestCase"
	output = false
	hint = "I test the distributed lock and related components."
	{

	public void function test_that_get_release_lifecycle_works() {

		// CAUTION: Have to store in Variables scope to make available in threads.
		variables.jedisClient = getJedisKeyServer( 50, 1 );

		var lockName = "lifecycle-test";

		for ( var i = 0 ; i < 10 ; i++ ) {

			var myLock = jedisClient.getLock( lockName, ( 10 * 1000 ) );

			thread 
				name = "jedis-workflow-racer#i#" 
				lockName = lockName 
				{

				// Expecting this one to fail since the outer lock hasn't been released.
				var innerLock = jedisClient.getLock( lockName, 10 );

			}

			thread action = "join";

			assert( cfthread[ "jedis-workflow-racer#i#" ].error.message == "The distributed lock could not be obtained." );

			myLock.releaseLock();

		}

		// Clean up test.
		structDelete( variables, "jedisClient" );

	}


	public void function test_that_detach_key_will_expire() {

		var jedisClient = getJedisKeyServer( 50, 1 );

		var myLock = jedisClient.getLock( "detached-key-test", 1000 );

		sleep( 50 );

		try {

			var myLock2 = jedisClient.getLock( "detached-key-test", 10 );

			// Expecting the above request to throw an error.
			assert( false );

		} catch ( any error ) {

			// Expected this error.

		}

		sleep( 1000 );

		// Expecting the key to be available again.
		var myLock3 = jedisClient.getLock( "detached-key-test", 10 );

		myLock.releaseLock();
		myLock3.releaseLock();

	}


	// ---
	// PRIVATE METHODS.
	// ---


	private any function getJedisKeyServer( 
		required numeric retryDelayInMilliseconds,
		required numeric maxRetryCount
		) {

		// Create a JedisPool instance that talks to the locally-hosted Redis server.
		var jedisPool = createObject( "java", "redis.clients.jedis.JedisPool" ).init(
			createObject( "java", "redis.clients.jedis.JedisPoolConfig" ).init(),
			javaCast( "string", "127.0.0.1" )
		);

		return( 
			new lib.CFRedlock().createJedisClient(
				[ jedisPool ],
				retryDelayInMilliseconds,
				maxRetryCount
			)
		);

	}

}