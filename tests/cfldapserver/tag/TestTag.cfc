<cfcomponent displayname="TestInstall"  extends="mxunit.framework.TestCase">

	<cfimport taglib="/cfldapserver/tag/cfldapserver" prefix="gm" />

	<cffunction name="setUp" returntype="void" access="public">
		<cfset datapath = "#getDirectoryFromPath(getMetadata(this).path)#../../data" />
 	</cffunction>

	<cffunction name="tearDown" returntype="void" access="public">
<!---
		<cfset request.debug("stopping") />
		<gm:ldapserver action="stop" />
 --->
	</cffunction>

	<cffunction name="testStartStop">
		<gm:ldapserver action="start"/>
		<gm:ldapserver action="stop"/>
	</cffunction>

	<cffunction name="testStartStopDifferentPort">
		<gm:ldapserver action="start" port="10399" enableSSL="false"/>
		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10399"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfcatch>
				<cfset fail("could not query server") />
			</cfcatch>
			<cffinally>
				<gm:ldapserver action="stop"/>
			</cffinally>
		</cftry>
		<cfset debug(data) />
	</cffunction>

	<cffunction name="testSetPassword">
		<cfset var password = "testtest" />
		<gm:ldapserver action="start" port="10389" enableSSL="false"/>
		<gm:ldapserver action="setAdminPassword" password="#password#"/>
		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389"
			username="uid=admin,ou=system"
			password="secret"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfcatch>
				<cfif NOT findNoCase("INVALID_CREDENTIALS",cfcatch.message)>
					<gm:ldapserver action="start" port="10389" enableSSL="false"/>
					<cfset fail("this password should have failed :" & cfcatch.message) />
				</cfif>
			</cfcatch>
		</cftry>
		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389"
			username="uid=admin,ou=system"
			password="#password#"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfcatch>
				<cfset fail("could not query server :" & cfcatch.message) />
			</cfcatch>
		</cftry>
		<gm:ldapserver action="setAdminPassword" password="secret"/>
		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389"
			username="uid=admin,ou=system"
			password="secret"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfcatch>
				<cfset fail("could not query server") />
			</cfcatch>
			<cffinally>
				<gm:ldapserver action="stop"/>
			</cffinally>
		</cftry>
		<cfset debug(data) />
	</cffunction>

	<cffunction name="testSSL">
		<gm:ldapserver action="start" allowAnonymousAccess="true"/>
		<cftry>
			<cfset SSLCertificateInstall("127.0.0.1",10389)>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389" secure="CFSSL_BASIC"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfcatch>
				<cfset fail("could not query server") />
			</cfcatch>
			<cffinally>
				<gm:ldapserver action="stop"/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="testNoSSL">
		<gm:ldapserver action="start" enableSSL="false" allowAnonymousAccess="true"/>

		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">

			<cfset debug(data) />
			<cfcatch>
				<cfset cfcatch.printstacktrace()>
				<cfset fail("could not query server : " & cfcatch.message) />
			</cfcatch>
			<cffinally>
				<gm:ldapserver action="stop"/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="testRequireAuthentication">
		<gm:ldapserver action="start" enableSSL="false" allowAnonymousAccess="true"/>
		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfset debug(data) />
			<cfcatch>
				<cfset fail("could not query server :" & cfcatch.message) />
			</cfcatch>
			<cffinally>
				<gm:ldapserver action="stop"/>
			</cffinally>
		</cftry>
		<gm:ldapserver action="start" enableSSL="false" allowAnonymousAccess="false"/>
		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389"
			scope="subtree"
			start = "dc=apache,dc=org"
			username="uid=admin,ou=system"
			password="secret"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfset debug(data) />
			<cfcatch>
				<cfset fail("could not query server :" & cfcatch.message) />
			</cfcatch>
		</cftry>
		<cftry>
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389"
			scope="subtree"
			start = "dc=apache,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfcatch>
				<cfif NOT findNoCase("unauthenticated caller",cfcatch.message)>
					<cfset fail("this password should have failed: " & cfcatch.message) />
				</cfif>
			</cfcatch>
			<cffinally>
				<gm:ldapserver action="stop"/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="testCFLDAP">
		<gm:ldapserver action="start" allowAnonymousAccess="true"/>
		<cfset SSLCertificateInstall("127.0.0.1",10389) />
		<cfldap
		server = "127.0.0.1"
		action ="query"
		name = "data"
		port="10389" secure="CFSSL_BASIC"
		scope="subtree"
		start = ""
		filter = "dc=Apache"
		attributes = "uid,dn,dc,c,o,ou,cn,mail">

		<cfset request.debug(data) />

		<cfldap
		server = "127.0.0.1"
		username="uid=admin,ou=system"
		password="secret"
		action ="query"
		name = "data"
		port="10389" secure="CFSSL_BASIC"
		scope="onelevel"
		start = "dc=apache,dc=org"
		filter = "(objectClass=*)"
		attributes = "uid,dn,dc,c,o,ou,cn,mail">

		<cfset request.debug(data) />
		<cfldap action="modify" dn="uid=admin,ou=system"
				username="uid=admin,ou=system"
				password="secret"
				attributes="userPassword=secret"
				separator=";"
				port="10389" secure="CFSSL_BASIC"
				server="127.0.0.1" />

		<cfldap action="ADD"
				username="uid=admin,ou=system"
				password="secret"
				dn="cn=Robert Smith,ou=people,dc=apache,dc=org"
				attributes="objectclass=inetOrgPerson; givenname=Thomas;sn=Hardy;cn=Thomas Hardy;mail=thardy@mama.com"
				separator=";"
				port="10389" secure="CFSSL_BASIC"
				server="127.0.0.1" />

		<cfldap
			server = "127.0.0.1"
			username="uid=admin,ou=system"
			password="secret"
			action ="query"
			name = "data"
			port="10389" secure="CFSSL_BASIC"
			scope="subtree"
			start = "ou=people,dc=apache,dc=org"
			filter = "(&(cn=Robert Smith))"
		attributes = "uid,dn,dc,c,o,ou,cn,mail">

		<cfset request.debug(data) />

		<cfset assertTrue(structKeyExists(data,'dn')) />
		<cfset assertEquals("cn=robert smith,ou=people,dc=apache,dc=org",data.dn) />

		<cfldap action="MODIFY"
				username="uid=admin,ou=system"
				password="secret"
				dn="cn=Robert Smith,ou=people,dc=apache,dc=org"
				attributes="mail=somethingelse@mama.com"
				separator=";"
				port="10389" secure="CFSSL_BASIC"
				server="127.0.0.1" />

		<cfldap action="DELETE"
				username="uid=admin,ou=system"
				password="secret"
				dn="cn=Robert Smith,ou=people,dc=apache,dc=org"
				port="10389" secure="CFSSL_BASIC"
				server="127.0.0.1" />

		<gm:ldapserver action="stop"/>

	</cffunction>


	<cffunction name="testAddPartition">
		<cftry>
			<gm:ldapserver action="start" allowAnonymousAccess="true"/>
			<gm:ldapserver action="addPartition" partitionId="testPartition" partitionDn="dc=cfldapserver,dc=org" />
			<cfset debug(ldapserver) />
			<cfldap
			server = "127.0.0.1"
			action ="query"
			name = "data"
			port="10389" secure="CFSSL_BASIC"
			scope="subtree"
			start = "dc=cfldapserver,dc=org"
			filter = "(objectClass=*)"
			attributes = "uid,dn,dc,c,o,ou,cn,mail">
			<cfcatch>
				<cfset fail("could not query server: " & cfcatch.message) />
			</cfcatch>
			<cffinally>
				<gm:ldapserver action="stop"/>
			</cffinally>
		</cftry>
	</cffunction>


</cfcomponent>
