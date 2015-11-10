component
	output = false
	hint = "I provide a client that can acquire distributed locks."
	{

	/**
	* I create a distributed lock client using the given servers to implement the
	* Redlock distributed locking algorithm.
	* 
	* @keyServers I am the collection of key servers.
	* @retryDelayInMilliseconds I am the approximate delay to use between retries.
	* @maxRetryCount I am the number of times to retry acquiring a lock before failure.
	* @output false
	*/
	public any function init(
		required array keyServers,
		required numeric retryDelayInMilliseconds,
		required numeric maxRetryCount
		) {

		setKeyServers( keyServers );
		setRetryDelayInMilliseconds( retryDelayInMilliseconds );
		setMaxRetryCount( maxRetryCount );

		// By default, no prefix will be added to the lock keys.
		setPrefix( "" );

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I attempt to acquire a distributed lock with the given name. If the lock can be 
	* obtained, the closure is run. If the lock cannot be acquired, an error is thrown.
	* 
	* The result of the closure execution is returned.
	* 
	* @name I am the name of the lock.
	* @ttlInMilliseconds I am the time-to-live of the lock, after which it will auto-expire.
	* @operator I am the closure that executes the lock body.
	* @output false
	*/
	public any function executeLock(
		required string name,
		required numeric ttlInMilliseconds,
		required function opereator
		) {

		try {

			var acquiredLock = getLock( name, ttlInMilliseconds );

			return( opereator() );

		} finally {

			if ( structKeyExists( local, "acquiredLock" ) ) {

				acquiredLock.releaseLock();

			}

		}

	}


	/**
	* I attempt to acquire a distributed lock with the given name. If the lock can be 
	* obtained, the closure is run. If the lock cannot be acquired, the closure is 
	* skipped and no error is thrown. 
	* 
	* The result of the closure execution is returned; however, if the lock could not
	* be acquired, the result will be null.
	* 
	* @name I am the name of the lock.
	* @ttlInMilliseconds I am the time-to-live of the lock, after which it will auto-expire.
	* @operator I am the closure that executes the lock body.
	* @output false
	*/
	public any function executeLockOrSkip(
		required string name,
		required numeric ttlInMilliseconds,
		required function opereator
		) {

		try {

			return( executeLock( name, ttlInMilliseconds, opereator ) );

		// We only want to catch and swallow lock-failure errors. All other error types
		// should bubble-up to the calling context where the code can deal with them.
		} catch ( CFRedlock.LockFailure error ) {

			// Swallow the error, nothing to return.

		}

	}


	/**
	* I attempt to acquire a distributed lock with the given name. If the lock cannot
	* be acquired, an error is thrown.
	* 
	* @name I am the name of the lock.
	* @ttlInMilliseconds I am the time-to-live of the lock, after which it will auto-expire.
	* @output false
	*/
	public any function getLock(
		required string name,
		required numeric ttlInMilliseconds
		) {

		var lockName = ( prefix & name );

		// When the lock keys are created, they are associated with a "random" value. 
		// This value is used for confirmation during the delete command so that an 
		// expired lock cannot accidentally delete keys that were subsequently created
		// by a newly acquired lock.
		var lockToken = createUUID();

		// When acquiring the distributed lock, the lock will only be considered 
		// acquired if the lock keys were stored on a majority (ie, more than half) of 
		// the available key servers.
		var majorityCount = ( fix( arrayLen( keyServers ) / 2 ) + 1 );

		var remainingRetries = maxRetryCount;

		// Try to acquire the lock while we have remaining retries.
		do {

			// We need to keep track of how long it takes to iterate over the servers
			// since the duration of the operation will affect the "validity time" of
			// the lock once they keys are set.
			var startedAt = getTickCount();

			var acquiredLockCount = 0;

			// Try to store the key in each server.
			for ( var keyServer in keyServers ) {

				if ( keyServer.setKey( lockName, lockToken, ttlInMilliseconds ) ) {

					acquiredLockCount++;

				}
		
			}

			// Now that the keys are set (or were attempted to be set), we have to figure
			// out how much time is left in the original time-to-live of the lock. Since
			// we are dealing with a distributed system, we have to account for both the
			// duration of the server-iteration as well as the possible clock differences
			// (ie, drift) between the various key servers.
			// --
			// FROM THE DOCS ( http://redis.io/topics/distlock ):
			// The algorithm relies on the assumption that while there is no synchronized 
			// clock across the processes, still the local time in every process flows 
			// approximately at the same rate, with an error which is small compared to 
			// the auto-release time of the lock. This assumption closely resembles a 
			// real-world computer: every computer has a local clock and we can usually 
			// rely on different computers to have a clock drift which is small.
			var clockDrift = ( ( ttlInMilliseconds * 0.02 ) + 2 );
			var iterationDelta = ( getTickCount() - startedAt );
			
			// NOTE: Using max() to turn into a Truthy / Falsey value - a negative number
			// is considered a falsey in this case.
			var ttlRemaining = max( ( ttlInMilliseconds - iterationDelta - clockDrift ), 0 );

			// The lock is only considered acquired if the keys were set on a majority 
			// of the servers AND there is still some time remaining in the TTL.
			if ( ( acquiredLockCount >= majorityCount ) && ttlRemaining ) {

				// NOTE: AcquiredLock() instance is given NON-PREFIXED name.
				return( new AcquiredLock( this, name, lockToken ) );

			}

			// CAUTION: If we made it this far THE LOCK WAS NOT ACQUIRED.

			// Remove the key from each server before we [potentially] try again.
			for ( var keyServer in keyServers ) {

				keyServer.deleteKey( lockName, lockToken );
		
			}

			// Sleep for a random(ish) time before retrying. This is done to try and 
			// desynchronize clients that may be in a race for the same lock.
			// --
			// NOTE: Using post-decrement operator so that the IF statement applies to 
			// the current value, not the decremented one.
            if ( remainingRetries-- ) {

            	sleep( randRange( fix( retryDelayInMilliseconds / 2 ), retryDelayInMilliseconds ) );

            }

		} while ( remainingRetries );

		// If we made it this far, no lock was obtained.
		throw(
			type = "CFRedlock.LockFailure",
			message = "The distributed lock could not be obtained.",
			detail = "The distributed lock [#name#][#lockName#] could not obtained."
		);

	}


	/**
	* I release the lock with the given name and confirmation token.
	*  
	* @name I am the name of the distributed lock.
	* @token I am the confirmation token associated with the lock.
	* @output false
	*/
	public void function releaseLock(
		required string name,
		required string token
		) {

		var lockName = ( prefix & name );
		var lockToken = token;

		for ( var keyServer in keyServers ) {

			keyServer.deleteKey( lockName, lockToken );
	
		}

	}


	/**
	* I set the lock name prefix. The prefix is prepended to each lock name, internally,
	* before it is set. This allows you to namespace lock keys for easier debugging.
	* 
	* @newPrefix I am the lock name prefix.
	* @output false
	*/
	public any function setPrefix( required string newPrefix ) {

		testPrefix( newPrefix );

		prefix = newPrefix;

		return( this );

	}


	/**
	* I test the name prefix. If the prefix is invalid, I throw an exception.
	* 
	* @newPrefix I am the name prefix being tested.
	* @output false
	*/
	public void function testPrefix( required string newPrefix ) {

		// ...

	}


	// ---
	// PRIVATE METHODS.
	// ---


	/**
	* I set the distributed key servers.
	* 
	* @newKeyServers I am the collection of key servers.
	* @output false
	*/
	private void function setKeyServers( required array newKeyServers ) {

		testKeyServers( newKeyServers );

		keyServers = newKeyServers;

	}


	/**
	* I set the max retry count to be used when trying to acquire the lock.
	* 
	* @newMaxRetryCount I am the number of retry attempts.
	* @output false
	*/
	private void function setMaxRetryCount( required numeric newMaxRetryCount ) {

		testMaxRetryCount( newMaxRetryCount );

		maxRetryCount = newMaxRetryCount;

	}


	/**
	* I set the max duration to wait between retry attempts.
	* 
	* NOTE: This is an approximate value since the retry delay is actually a random
	* range based on this value (the randomness is done to try and desynchronize multiple
	* requests that are racing to obtain the same lock).
	* 
	* @newRetryDelayInMilliseconds I am the time to wait between retry attempts.
	* @output false
	*/
	private void function setRetryDelayInMilliseconds( required numeric newRetryDelayInMilliseconds ) {

		testRetryDelayInMilliseconds( newRetryDelayInMilliseconds );

		retryDelayInMilliseconds = newRetryDelayInMilliseconds;

	}


	/**
	* I test the key servers. If the servers are invalid, I throw an exception.
	* 
	* @newKeyServers I am the key servers being tested.
	* @output false
	*/
	private void function testKeyServers( required array newKeyServers ) {

		if ( ! arrayLen( newKeyServers ) ) {

			throw(
				type = "CFRedlock.InvalidArgument",
				message = "At least one key server instance must be provided."
			);

		}

	}


	/**
	* I test the max retry count. If the retry count is invalid, I throw an exception.
	* 
	* @newMaxRetryCount I am the max number of retry attempts to make.
	* @output false
	*/
	private void function testMaxRetryCount( required numeric newMaxRetryCount ) {

		if ( newMaxRetryCount < 0 ) {

			throw(
				type = "CFRedlock.InvalidArgument",
				message = "The max retry count must be a positive number, greater than or equal to zero.",
				detail = "The provided max retry count [#newMaxRetryCount#] must be greater than or equal to zero."
			);

		}

	}


	/**
	* I test the retry delay. If the retry delay is invalid, I throw an exception.
	* 
	* @newRetryDelayInMilliseconds I am the retry delay.
	* @output false
	*/
	private void function testRetryDelayInMilliseconds( required numeric newRetryDelayInMilliseconds ) {

		if ( newRetryDelayInMilliseconds < 50 ) {

			throw(
				type = "CFRedlock.InvalidArgument",
				message = "The retry delay must be greater than or equal to 50 milliseconds.",
				detail = "The provided retry delay [#newRetryDelayInMilliseconds#] must be greater than or equal to 50 milliseconds."
			);

		}

	}

}