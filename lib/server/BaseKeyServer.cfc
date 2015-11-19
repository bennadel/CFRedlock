component
	output = false
	hint = "I provide a common functionality for the key server interface."
	{

	/**
	* Do not create this component, extend it.
	*
	* @output false
	*/
	public any function init() {

		throw(
			type = "CFRedlock.NotSupported",
			message = "The BaseKeyServer is meant to be extended, not instantiated."
		);

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I test the name of the new key. If the name is invalid, I throw an exception.
	*
	* @newName I am the name of the new key.
	* @output false
	*/
	public void function testName( required string newName ) {

		if ( ! len( trim( arguments.newName ) ) ) {

			throw(
				type = "CFRedlock.InvalidArgument",
				message = "The key name cannot be empty.",
				detail = "The supplied key [#arguments.newName#] cannot be empty."
			);

		}

	}


	/**
	* I test the value being stored at the key. If the value is invalid, I throw an
	* exception.
	*
	* @newValue I am the value being stored.
	* @output false
	*/
	public void function testValue( required string newValue ) {

		// ...

	}


	/**
	* I test the time-to-live for the key expiration. If the TTL is invalid, I throw an
	* exception.
	*
	* @newTtlInMilliseconds I am the TTL being provided for the key.
	* @output false
	*/
	public void function testTtlInMillseconds( required string newTtlInMilliseconds ) {

		if ( arguments.newTtlInMilliseconds <= 0 ) {

			throw(
				type = "CFRedlock.InvalidArgument",
				message = "The time-to-live must be a positive number.",
				detail = "The time-to-live [#arguments.newTtlInMilliseconds#] must be a positive number."
			);

		}

	}

}