<cfcomponent>

	<cfset this.metadata.attributetype="mixed">
	<cfset this.metadata.attributes={
		action=			{required=true,type="string"},
		port=		{required=true,type="numeric",default=10389},
		sslEnable=		{required=true,type="boolean",default=true},
		allowAnonymousAccess=		{required=true,type="boolean",default=true},
		name=	{required=false,type="string",default="ldapserver"}
		}/>
	<cfset _log = [] />
	<!--- no need to recreate these every time, only using them for static vars and methods --->
	<cfset directoryserver = new DirectoryServer() />

	<cffunction name="onStartTag" output="yes" returntype="boolean">
		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">
		<cfif structKeyExists(attributes,"argumentCollection")>
			<cfset attributes = attributes.argumentCollection />
		</cfif>
		<cfscript>
			caller[attributes.name] = runAction(attributes);
		</cfscript>
		<cfif not variables.hasEndTag>
			<cfset onEndTag(attributes,caller,"") />
		</cfif>
		<cfreturn variables.hasEndTag>
	</cffunction>

	<cffunction name="onEndTag" output="yes" returntype="boolean">
		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">
		<cfargument name="generatedContent" type="string">
		<cfreturn false/>
	</cffunction>

	<cffunction name="runAction">
		<cfargument name="args" required="true" />
		<cfset _init(argumentCollection = args) />
		<cfscript>
			return request.gmserver.callMethod(methodName=args.action, args = args);
		</cfscript>
	</cffunction>

	<cffunction name="_init" output="no" returntype="void" hint="invoked after tag is constructed">
		<cfif !structKeyExists(server,"gmserver") || structKeyExists(arguments,"reinit")>
			<cfset server.gmserver = directoryserver.init() />
		</cfif>
		<cfset request.gmserver = server.gmserver />
	</cffunction>

	<cffunction name="init" output="no" returntype="void" hint="invoked after tag is constructed">
		<cfargument name="hasEndTag" type="boolean" required="yes" />
		<cfargument name="parent" type="component" required="no" hint="the parent cfc custom tag, if there is one" />
		<cfset _init() />
		<cfset variables.hasEndTag = arguments.hasEndTag />
	</cffunction>

	<cffunction name="random" access="public" output="No" returnType="any"
		hint="returns all emails">
		<cfset ldapserverUtil.random() />
	</cffunction>

</cfcomponent>
