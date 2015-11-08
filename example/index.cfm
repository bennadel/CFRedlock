<cfscript>

	// Create a lock that will automatically expire in 60-seconds.
	// --
	// NOTE: The expiration date is required and is there to ensure that a lock
	// won't remain in-place indefinitely if the client code forgets to close it
	// of fails to close it due to local or network error.
	// -- 
	// CAUTION: If this call fails to obtain a lock, an error is thrown.
	myLock = application.locking.getLock( "my-first-lock", ( 20 * 1000 ) );

	// Since we always want to release the obtained lock, no matter what, we need to
	// execute our synchronized logic in a try-finally where the finally block will 
	// release the lock in all possible outcomes.
	try {

		// Do your synchronized code here.
		writeOutput( "Locking like a boss!" );

		// CAUTION: Sleep is here to allow a page refresh to fail to get a lock.
		sleep( 5 * 1000 );

	// No matter what happens, release the lock.
	} finally {

		myLock.releaseLock();

	}

</cfscript>