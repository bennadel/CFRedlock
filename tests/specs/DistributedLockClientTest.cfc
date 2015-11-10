component
	extends = "TestCase"
	output = false
	hint = "I test the distributed lock and related components."
	{

	public void function test_that_test_servers_work() {

		// Test that N-number of GOOD servers works.
		for ( var i = 1 ; i < 10 ; i++ ) {

			var serverConfigurations = [];

			for ( var n = 1 ; n <= i ; n++ ) {

				arrayAppend( serverConfigurations, [ true, true ] );

			}

			var passClient = new lib.CFRedlock().createTestClient( serverConfigurations );
				
			var myLock = passClient.getLock( "my-lock", 1000 );

			myLock.releaseLock();

		}


		// Test that any number of BAD servers fails.
		// --
		// NOTE: This test will take some time since 
		for ( var i = 1 ; i < 10 ; i++ ) {

			var serverConfigurations = [];

			for ( var n = 1 ; n <= i ; n++ ) {

				arrayAppend( serverConfigurations, [ false, false ] );

			}

			var passClient = new lib.CFRedlock().createTestClient( serverConfigurations, 50 );
				
			try {

				var myLock = passClient.getLock( "my-lock", 1000 );

				// We are expecting the above to FAIL. As such, if we get this far, then the test failed.
				assert( false );

			} catch ( any error ) {
				
				// We expected this failure.

			}

		}


		// Test that a majority of GOOD servers work.
		var passClient = new lib.CFRedlock().createTestClient( 
			[
				[ true, true ], // Good.
				[ false, true ],
				[ true, true ], // Good.
				[ false, true ],
				[ true, true ] // Good.
			]
		);

		var myLock = passClient.getLock( "my-lock", 1000 );

		myLock.releaseLock();


		// Test that a majority of BAD servers fail.
		var passClient = new lib.CFRedlock().createTestClient( 
			[
				[ false, true ],
				[ true, true ], // Good.
				[ false, true ],
				[ true, true ], // Good.
				[ false, true ]
			]
		);

		try {

			var myLock = passClient.getLock( "my-lock", 1000 );

			// We are expecting the above to FAIL. As such, if we get this far, then the test failed.
			assert( false );

		} catch ( any error ) {

			// We expected this failure.

		}

	}


	public void function test_that_race_conditions_fail() {

		// To test race conditions, we are going to create an isolated ColdFusion client.
		// --
		// CAUTION: Have to store in Variables scope to make available in threads.
		variables.cfClient = new lib.CFRedlock().createIsolatedClient();

		var lockName = "race-condition-test";
		var threadNames = [ "cf-racerA", "cf-racerB", "cf-racerC", "cf-racerD" ];

		// Since all the threads are using the same lock-name, we expected 1 to pass and N-1 to fail.
		for ( var threadName in threadNames ) {

			thread 
				name = threadName
				lockName = lockName
				{

				var myLock = cfClient.getLock( lockName, ( 10 * 1000 ) );

				try {

					sleep( 3 * 1000 );

				} finally {

					myLock.releaseLock();

				}

			}

		}

		thread action = "join";

		var passCount = 0;
		var failCount = 0;

		for ( var threadName in threadNames ) {

			if ( structKeyExists( cfthread[ threadName ], "error" ) ) {

				failCount++;

				assert( cfthread[ threadName ].error.message == "The distributed lock could not be obtained." );

			} else {

				passCount++;

			}

		}

		assert( passCount == 1 );
		assert( failCount == ( arrayLen( threadNames ) - 1 ) );


		// Now that the threads have joined, we expect a new one to work.
		try {

			myLock = cfClient
				.getLock( lockName, ( 10 * 1000 ) )
				.releaseLock()
			;

		} catch ( any error ) {

			assert( false );

		}

		// Clean up test.
		structDelete( variables, "cfClient" );

	}


	public void function test_that_get_release_lifecycle_works() {

		// CAUTION: Have to store in Variables scope to make available in threads.
		variables.cfClient = new lib.CFRedlock().createIsolatedClient( 50 );

		var lockName = "lifecycle-test";

		for ( var i = 0 ; i < 10 ; i++ ) {

			var myLock = cfClient.getLock( lockName, ( 10 * 1000 ) );

			thread 
				name = "cf-worfklow-racer#i#" 
				lockName = lockName 
				{

				// Expecting this one to fail since the outer lock hasn't been released.
				var innerLock = cfClient.getLock( lockName, 10 );

			}

			thread action = "join";

			assert( cfthread[ "cf-worfklow-racer#i#" ].error.message == "The distributed lock could not be obtained." );

			myLock.releaseLock();

		}

		// Clean up test.
		structDelete( variables, "cfClient" );

	}


	public void function test_that_detach_key_will_expire() {

		var cfClient = new lib.CFRedlock().createIsolatedClient( 50 );

		var myLock = cfClient.getLock( "detached-key-test", 1000 );

		sleep( 50 );

		try {

			var myLock2 = cfClient.getLock( "detached-key-test", 10 );

			// Expecting the above request to throw an error.
			assert( false );

		} catch ( any error ) {

			// Expected this error.

		}

		sleep( 1000 );

		// Expecting the key to be available again.
		var myLock3 = cfClient.getLock( "detached-key-test", 10 );

		myLock.releaseLock();
		myLock3.releaseLock();

	}


	public void function test_that_execute_lock_lifecycle_works() {

		// CAUTION: Have to store in Variables scope to make available in threads.
		variables.cfClient = new lib.CFRedlock().createIsolatedClient( 50 );

		var lockName = "lifecycle-test";

		for ( var i = 0 ; i < 10 ; i++ ) {

			cfClient.executeLock(
				lockName,
				( 10 * 1000 ),
				function() {

					thread
						name = "closure-workflow-racer#i#"
						lockName = lockName
						{

						// Expecting this one to fail since we are currently inside another lock.
						var innerLock = cfClient.getLock( lockName, 10 );

					}

					thread action = "join";

					assert( cfthread[ "closure-workflow-racer#i#" ].error.message == "The distributed lock could not be obtained." );


				}
			);

		}

		// Clean up test.
		structDelete( variables, "cfClient" );

	}


	public void function test_that_execute_lock_or_skip_lifecycle_works() {

		var cfClient = new lib.CFRedlock().createIsolatedClient( 50 );

		var lockName = "lifecycle-test";

		for ( var i = 0 ; i < 10 ; i++ ) {

			cfClient.executeLock(
				lockName,
				( 10 * 1000 ),
				function() {

					cfClient.executeLockOrSkip( lockName, 10, function(){} );

				}
			);

		}

	}


	public void function test_that_skip_doesn_swallow_valid_errors() {

		var cfClient = new lib.CFRedlock().createIsolatedClient( 50 );

		try {

			cfClient.executeLockOrSkip(
				"error-test",
				( 10 * 1000 ),
				function() {

					var x = UNDEFINED_VALUE;

				}
			);

			// We are expecting the above to throw an error.
			assert( false );

		} catch ( "CFRedlock.LockFailure" error ) {

			assert( false );

		} catch ( any error ) {

			assert( true );

		}

	}

}