<cfoutput>

	<cfif ( error.type eq "CFRedlock.LockFailure" )>
		
		<h1>
			Locking Error
		</h1>

		<p>
			Your lock could not be acquired.
		</p>

		<p>
			<strong>Message</strong>: #htmlEditFormat( error.detail )#
		</p>

	<cfelse>

		<h1>
			Oops: Something Went Wrong
		</h1>

		<cfdump var="#error#" />

	</cfif>

</cfoutput>