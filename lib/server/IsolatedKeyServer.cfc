component
	extends = "BaseKeyServer"
	output = false
	hint = "I provide a normalized, atomic key server interface for an isolated ColdFusion instance."
	{

	/**
	* I create a new key server using an internally-synchronized key store. Since this
	* solution uses the native CFLock, it is assumed that this server will be used as
	* part of a single-server in isolation.
	*
	* The value-add of this implementation is that you can consume a distributed-locking
	* interface without having to have the infrastructure in place to support it. So,
	* essentially, this just replaced the native lock { ... } semantics until a multi-
	* server, fail-over solution can be swapped-in.
	*
	* @output false
	*/
	public any function init() {

		// I hold the cached keys.
		// --
		// CAUTION: Only the "happy path" deletes keys from this store. As such, this
		// may start to accumulate keys over time. However, since this only stores a
		// tiny amount of data and only in the "sad path", I don't anticipate this ever
		// becoming a problem.
		variables.keyStore = {};

		// I am the name of the ColdFusion lock used to synchronize keyStore access.
		variables.isolatedLockName = "CFRedlockIsolatedServer-#createUUID()#";

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

		lock
			type = "exclusive"
			name = variables.isolatedLockName
			timeout = 1
			{

			// If the key doesn't exist, there's nothing to delete.
			if ( ! structKeyExists( variables.keyStore, arguments.name ) ) {

				return( false );

			}

			// If the stored value doesn't match, we cannot delete the key.
			if ( variables.keyStore[ arguments.name ].value != arguments.value ) {

				return( false );

			}

			structDelete( variables.keyStore, arguments.name );

			return( true );

		}

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

		testName( arguments.name );
		testValue( arguments.value );
		testTtlInMillseconds( arguments.ttlInMilliseconds );

		lock
			type = "exclusive"
			name = variables.isolatedLockName
			timeout = 1
			{

			// If the key already exists, and is not expired, we can't overwrite it.
			if ( structKeyExists( variables.keyStore, arguments.name ) && ( variables.keyStore[ arguments.name ].expires > getTickCount() ) ) {

				return( false );

			}

			variables.keyStore[ arguments.name ] = {
				value: arguments.value,
				expires: ( getTickCount() + arguments.ttlInMilliseconds )
			};

			return( true );

		}

	}

}