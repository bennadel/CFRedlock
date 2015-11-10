<cfscript>

	// The .executeLock() method will obtain the lock internally, synchronize the 
	// execution of your closure (based on the distributed lock name) and then 
	// automatically release the lock when your code is done executing. Functionally 
	// speaking, all this is really doing is pushing the lock management into the client,
	// rather than leaving it in your calling code.
	// --
	// CAUTION: If this call fails to obtain a lock, an error is thrown.
	result = application.locking.executeLock(
		"my-first-lock",
		( 20 * 1000 ),
		function() {

			// CAUTION: Sleep is here to allow a page refresh to fail to get a lock.
			sleep( 5 * 1000 );

			return( "Locking with closures!" );

		}
	);

	// Since the .executeLock() method will throw an error if the lock failed, we can 
	// be confident that we have a return value / result to consume.
	writeOutput( result );

</cfscript>
