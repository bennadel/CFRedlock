<cfscript>

	// The .executeLockOrSkip() method will obtain the lock internally, synchronize 
	// the execution of your closure (based on the distributed lock name) and then 
	// automatically release the lock when your code is done executing. Unlike the 
	// .executeLock() method, this method will NOT throw an error if the lock cannot 
	// be acquired. If the lock fails, the execution of the closure is simply skipped
	// without incident.
	// --
	// CAUTION: If this call fails to obtain a lock, NO ERROR is thrown.
	result = application.locking.executeLockOrSkip(
		"my-first-lock",
		( 20 * 1000 ),
		function() {

			// CAUTION: Sleep is here to allow a page refresh to fail to get a lock.
			sleep( 5 * 1000 );

			return( "Locking with closures!" );

		}
	);

	// Since the .executeLockOrSkip() method WILL NOT throw an error on lock failure, 
	// we may or may NOT have a result value to consume. 
	if ( isNull( result ) ) {

		writeOutput( "Lock (and operator) skipped." );

	} else {

		writeOutput( result );

	}

</cfscript>