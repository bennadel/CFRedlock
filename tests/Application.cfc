component
	extends = "tinytest.Application"
	output = false
	hint = "I provide the application settings and event handlers for your testing." 
	{

	// Add any mappings that you need in order to load your modules from within
	// the unit test specifications.
	// --
	// NOTE: You can use the evaluatePathTraversal() method to navigate upto your application,
	// and then down into any ColdFusion libraries you need to reference.
	this.mappings[ "/app" ] = evaluatePathTraversal( "../" );
	this.mappings[ "/lib" ] = evaluatePathTraversal( "../lib/" );
	this.mappings[ "/jars" ] = evaluatePathTraversal( "../jars/" );

	// Set up the custom JAR files for this ColdFusion application. In order to use 
	// Redis, we need to the Jedis JAR and the Apache Commons Pool2 JAR file. Using
	// ColdFusion 10's per-application Java integration, we can make these available
	// in the class paths.
	this.javaSettings = {
		loadPaths: [
			this.mappings[ "/jars" ]
		],
		loadColdFusionClassPath: false,
		reloadOnChange: false
	};

}