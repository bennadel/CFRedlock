component
	extends = "BaseKeyServer"
	output = false
	hint = "I provide a normalized, atomic key server interface on top of a Jedis connection pool."
	{

	/**
	* I create a new key server using the given jedisPool.
	* 
	* @jedisPool I am the Jedis connection pool used to talk to Redis.
	* @output false
	*/
	public any function init( required any jedisPool ) {

		setJedisPool( jedisPool );

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I delete the key with the given name, but only if it contains the given value.
	* If the key is deleted, returned true, otherwise returns false.
	* 
	* @name I am name of the key being deleted.
	* @value I am the confirmation value of the key being deleted.
	* @output false
	*/
	public boolean function deleteKey( 
		required string name,
		required string value
		) {

		try {
			
			var jedis = jedisPool.getResource();

			// This Lua script deletes the key, but only if the key contains the given
			// value. Returns 1 on success, otherwise returns 0.
			// --
			// TODO: Move to am embedded script with SHA identification.
			var result = jedis.eval(
				javaCast( 
					"string", 
					"
						if redis.call( 'get', KEYS[ 1 ] ) == ARGV[ 1 ] then
							return redis.call( 'del' ,KEYS[ 1 ] )
						else
							return 0
						end
					"
				),
				javaCast( "int", 1 ),
				javaCast( "string[]", [ name, value ] )
			);

			return( !! result );

		// Catch anything that went wrong with the connection or the logic.
		} catch ( any error ) {

			// If the error is anything other than a broken connection, rethrow.
			// --
			// NOTE: While we could catch this and just return a False, an unexpected
			// error may need to be logged at a higher level in the application.
			if ( error.type != "redis.clients.jedis.exceptions.JedisConnectionException" ) {

				rethrow;

			}

			// Return the broken connection to the connection pool.
			if ( structKeyExists( local, "jedis" ) ) {

				jedisPool.returnBrokenResource( jedis );

				structDelete( local, "jedis" );
				
			}

		// No matter what happens, return the connection to the pool.
		} finally {

			if ( structKeyExists( local, "jedis" ) ) {

				jedisPool.returnResource( jedis );
				
			}

		}

		// If we made it this far, then the key could not be deleted.
		return( false );

	}


	/**
	* I set a key with the given name to the given value. If not removed explicitly, 
	* the key will eventually expire after the given time-to-live.
	* 
	* @name I am the name of the key being set.
	* @value I am the confirmation value being stored with the key.
	* @ttlInMilliseconds I am the time-to-live after which the key will expire.
	* @output false
	*/
	public boolean function setKey(
		required string name,
		required string value,
		required numeric ttlInMilliseconds
		) {

		testName( name );
		testValue( value );
		testTtlInMillseconds( ttlInMilliseconds );

		try {

			var jedis = jedisPool.getResource();

			// The "NX" will only set the value if it doesn't already exists, otherwise returns null.
			var response = jedis.set(
				javaCast( "string", name ),
				javaCast( "string", value ),
				javaCast( "string", "NX" ),
				javaCast( "string", "PX" ),
				javaCast( "long", ttlInMilliseconds )
			);

			// If the response exists (ie, was not nullified), then the key was set.
			if ( structKeyExists( local, "response" ) ) {

				return( true );

			}

		// Catch anything that went wrong with the connection or the logic.
		} catch ( any error ) {

			// If the error is anything other than a broken connection, rethrow.
			// --
			// NOTE: While we could catch this and just return a False, an unexpected
			// error may need to be logged at a higher level in the application.
			if ( error.type != "redis.clients.jedis.exceptions.JedisConnectionException" ) {

				rethrow;

			}

			// Return the broken connection to the connection pool.
			if ( structKeyExists( local, "jedis" ) ) {

				jedisPool.returnBrokenResource( jedis );

				structDelete( local, "jedis" );
				
			}

		// No matter what happens, return the connection to the pool.
		} finally {

			if ( structKeyExists( local, "jedis" ) ) {

				jedisPool.returnResource( jedis );
				
			}

		}

		// If we made it this far, then the key could not be set.
		return( false );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	/**
	* I store the given jedisPool as the active connection pool.
	* 
	* @newJedisPool I am the jedisPool being set.
	* @output false
	*/
	private void function setJedisPool( required any newJedisPool ) {

		jedisPool = newJedisPool;

	}

}