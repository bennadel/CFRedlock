component
	extends = "BaseKeyServer"
	output = false
	hint = "I provide a normalized, atomic key server interface on top of static response value. This is for testing."
	{

	/**
	* I create a new key server using the given response values.
	* 
	* @setKeyResponse I am the response to use for all setKey commands.
	* @deleteKeyResponse I am the response to use for all deleteKey commands.
	* @output false
	*/
	public any function init( 
		required boolean setKeyResponse,
		required boolean deleteKeyResponse
		) {

		setSetKeyResponse( setKeyResponse );
		setDeleteKeyResponse( deleteKeyResponse );

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

		return( deleteKeyResponse );

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

		return( setKeyResponse );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	/**
	* I set the new deleteKey command response.
	* 
	* @newDeleteKeyResponse I am the value returned from all deleteKey() commands.
	* @output false
	*/
	private void function setDeleteKeyResponse( required boolean newDeleteKeyResponse ) {

		deleteKeyResponse = newDeleteKeyResponse;

	}


	/**
	* I set the new setKey command response.
	* 
	* @newSetKeyResponse I am the value returned from all setKey() commands.
	* @output false
	*/
	private void function setSetKeyResponse( required boolean newSetKeyResponse ) {

		setKeyResponse = newSetKeyResponse;

	}

}