<cfcomponent displayname="TestInstall"  extends="mxunit.framework.TestCase">

	<cfif findNoCase("railo",server.coldfusion.productname)>
		<cfinclude template="_TestInstall.cfm" />
	</cfif>

</cfcomponent>