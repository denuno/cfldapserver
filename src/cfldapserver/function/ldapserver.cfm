<cffunction name="ldapserver">
	<cfscript>
		var jm = createObject("WEB-INF.railo.customtags.cfldapserver.cfc.ldapserver");
		var results = jm.runAction(arguments);
		return results;
	</cfscript>
</cffunction>