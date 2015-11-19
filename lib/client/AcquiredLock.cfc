component
	output = false
	hint = "I represent an acquired lock in the distributed locking system."
	{

	/**
	* I create an acquired lock for the given client and key configuration.
	*
	* @distributedLockClient I am the distributed lock client that acquired the lock.
	* @name I am the name of the lock.
	* @token I am the confirmation value associated with the lock.
	* @output false
	*/
	public any function init(
		required any distributedLockClient,
		required string name,
		required string token
		) {

		setDistributedLockClient( arguments.distributedLockClient );
		setName( arguments.name );
		setToken( arguments.token );

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I extend the current lock's time-to-live.
	*
	* @timeInMilliseconds I am the amount of time for which to increase the the lock TTL.
	* @output false
	*/
	public void function extendLock( required numeric timeInMilliseconds ) {

		// TODO: Support this :D
		throw(
			type = "CFRedlock.NotYetSupported",
			message = "The extendLock() method is not yet supported."
		);

	}


	/**
	* I get the name of the current lock.
	*
	* CAUTION: The name reflects the value chosen by the calling context, not necessarily
	* the internally, normalized, and prefixed lock key.
	*
	* @output false
	*/
	public string function getName() {

		return( variables.name );

	}


	/**
	* I get the confirmation token associated with the current lock.
	*
	* @output false
	*/
	public string function getToken() {

		return( variables.token );

	}


	/**
	* I release the current lock.
	*
	* @output false
	*/
	public void function releaseLock() {

		variables.distributedLockClient.releaseLock( variables.name, variables.token );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	/**
	* I set the distributed lock client.
	*
	* @newDistributedLockClient I am the distributed lock client that acquired the lock.
	* @output false
	*/
	private void function setDistributedLockClient( required any newDistributedLockClient ) {

		variables.distributedLockClient = arguments.newDistributedLockClient;

	}


	/**
	* I set the name of the lock.
	*
	* @newName I am the name of the lock.
	* @output false
	*/
	private void function setName( required string newName ) {

		testName( arguments.newName );

		variables.name = arguments.newName;

	}


	/**
	* I set the confirmation token associated with the lock.
	*
	* @newToken I am the confirmation token associated with the lock.
	* @output false
	*/
	private void function setToken( required string newToken ) {

		testToken( arguments.newToken );

		variables.token = arguments.newToken;

	}


	/**
	* I test the lock name. If the name is invalid, I throw an exception.
	*
	* @newName I am the name being tested.
	* @output false
	*/
	private void function testName( required string newName ) {

		if ( ! len( trim( arguments.newName ) ) ) {

			throw(
				type = "CFRedlock.InvalidArgument",
				message = "The lock name must contain non-space characters."
			);

		}

	}


	/**
	* I test the lock token. If the token is invalid, I throw an exception.
	*
	* @newToken I am the confirmation token being tested.
	* @output false
	*/
	private void function testToken( required string newToken ) {

		if ( ! len( arguments.newToken ) ) {

			throw(
				type = "CFRedlock.InvalidArgument",
				message = "The lock token must not be empty."
			);

		}

	}

}