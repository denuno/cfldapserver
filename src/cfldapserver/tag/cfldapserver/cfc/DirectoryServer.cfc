<cfcomponent output="false"><cfscript>
/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

	thisDir = getDirectoryFromPath(getMetaData(this).path);
	cl = createObject("LibraryLoader").init(thisDir & "/lib/").init();
	system = cl.create("java.lang.System");
	jFile = cl.create("java.io.File");
	jHashSet = cl.create("java.util.HashSet");
	jList = cl.create("java.util.List");
	jArrayList = cl.create("java.util.ArrayList");

	jLdapConnection = cl.create("org.apache.directory.ldap.client.api.LdapConnection");
	jServerDNConstants = cl.create("org.apache.directory.server.constants.ServerDNConstants");
	jDefaultDirectoryService = cl.create("org.apache.directory.server.core.DefaultDirectoryService");
	jDirectoryService = cl.create("org.apache.directory.server.core.api.DirectoryService");
	jInstanceLayout = cl.create("org.apache.directory.server.core.api.InstanceLayout");
	jLdapCoreSessionConnection = cl.create("org.apache.directory.server.core.api.LdapCoreSessionConnection");
	jPartition = cl.create("org.apache.directory.server.core.api.partition.Partition");
	jSchemaPartition = cl.create("org.apache.directory.server.core.api.schema.SchemaPartition");
	jJdbmIndex = cl.create("org.apache.directory.server.core.partition.impl.btree.jdbm.JdbmIndex");
	jJdbmPartition = cl.create("org.apache.directory.server.core.partition.impl.btree.jdbm.JdbmPartition");
	jLdifPartition = cl.create("org.apache.directory.server.core.partition.ldif.LdifPartition");
	jLdapServer = cl.create("org.apache.directory.server.ldap.LdapServer");
	jTcpTransport = cl.create("org.apache.directory.server.protocol.shared.transport.TcpTransport");
	jIndex = cl.create("org.apache.directory.server.xdbm.Index");
	jEntry = cl.create("org.apache.directory.shared.ldap.model.entry.Entry");
	jLdapException = cl.create("org.apache.directory.shared.ldap.model.exception.LdapException");
	jDn = cl.create("org.apache.directory.shared.ldap.model.name.Dn");
	jRdn = cl.create("org.apache.directory.shared.ldap.model.name.Rdn");
	jSchemaManager = cl.create("org.apache.directory.shared.ldap.model.schema.SchemaManager");
	jSchemaLdifExtractor = cl.create("org.apache.directory.shared.ldap.schemaextractor.SchemaLdifExtractor");
	jDefaultSchemaLdifExtractor = cl.create("org.apache.directory.shared.ldap.schemaextractor.impl.DefaultSchemaLdifExtractor");
	jLdifSchemaLoader = cl.create("org.apache.directory.shared.ldap.schemaloader.LdifSchemaLoader");
	jDefaultSchemaManager = cl.create("org.apache.directory.shared.ldap.schemamanager.impl.DefaultSchemaManager");

	jDefaultModification = cl.create("org.apache.directory.shared.ldap.model.entry.DefaultModification");
	jModificationOperation = cl.create("org.apache.directory.shared.ldap.model.entry.ModificationOperation");

	public function init() {
		//jBasicConfigurator = cl.create("org.apache.log4j.BasicConfigurator");
		//jBasicConfigurator.configure();
		//jLog4jPropertyConfigurator = cl.create("org.apache.log4j.PropertyConfigurator");
		//jLog4jPropertyConfigurator.configure(getDirectoryFromPath(getMetadata(this).path) & "/lib/log4j.properties");
		return this;
	}

    function addPartition( String partitionId, String partitionDn )
    {
        var partition = jJdbmPartition.init(service.getSchemaManager());
        partition.setId( partitionId );
        partition.setPartitionPath( jFile.init( workDir, partitionId ).toURI() );
        var dn = jDn.init(strArray([partitionDn]));
        partition.setSuffixDn( dn );
        service.addPartition( partition );
        return partition;
    }

    /**
     * Add a new partition to the server
     *
     * @param partitionId The partition Id
     * @param partitionDn The partition DN
     * @return The newly added partition
     * @throws Exception If the partition can't be added
     */
    function addSystemPartition( String partitionId, String partitionDn )
    {
        var partition = jJdbmPartition.init(service.getSchemaManager());
        partition.setId( partitionId );
        partition.setPartitionPath( jFile.init( workDir, partitionId ).toURI() );
        var dn = jDn.init(strArray([partitionDn]));

        partition.setSuffixDn( dn );
        return partition;
    }

    /**
     * Add a new set of index on the given attributes
     *
     * @param partition The partition on which we want to add index
     * @param attrs The list of attributes to index
     */
    void function addIndex( partition, Array attrs )
    {
        // Index some attributes on the apache partition
        var indexedAttributes = jHashSet.init();
        var attrib = "";
        for ( attrib in attrs )
        {
            indexedAttributes.add( jJdbmIndex.init( attrib ) );
        }
        partition.setIndexedAttributes( indexedAttributes );
    }


    /**
     * initialize the schema manager and add the schema partition to diectory service
     *
     * @throws Exception if the schema LDIF files are not found on the classpath
     */
    void function initSchemaPartition()
    {
    	var schemaManager = service.getSchemaManager();
    	var schemaPartition = jSchemaPartition.init(schemaManager);
    	service.setSchemaPartition(schemaPartition);
        // Init the LdifPartition
        var ldifPartition = jLdifPartition.init(schemaManager);
        var schemaDir = jFile.init(workDir, "schema");
        //log("Schema directory: {}" & schemaDir);
		ldifPartition.setPartitionPath( schemaDir.toURI() );

        // Extract the schema on disk (a brand new one) and load the registries
		if (!schemaDir.exists()) {
			setRequestTimeout(180);
	        var extractor = jDefaultSchemaLdifExtractor.init( workDir );
	        extractor.extractOrCopy( true );
		}
        schemaPartition.setWrappedPartition( ldifPartition );
        schemaManager.setSchemaLoader(jLdifSchemaLoader.init(schemaDir));
        schemaManager.loadAllEnabled();
    }


    /**
     * Initialize the server. It creates the partition, adds the index, and
     * injects the context entries for the created partitions.
     *
     * @param workDir the directory to be used for storing the data
     * @throws Exception if there were some problems while initializing the system
     */
    void function initDirectoryService( workDir )
    {
        // Initialize the LDAP service
        service = jDefaultDirectoryService.init();
        service.setInstanceId("cfldapserver");
        service.setSchemaManager(jDefaultSchemaManager.init());
//      service.setWorkingDirectory( workDir );
        service.setInstanceLayout(jInstanceLayout.init(workDir));

        // first load the schema
        initSchemaPartition();

        // then the system partition
        // this is a MANDATORY partition
        var systemPartition = addSystemPartition( "system", jServerDNConstants.SYSTEM_DN );
        service.setSystemPartition( systemPartition );

        // Disable the ChangeLog system
        service.getChangeLog().setEnabled( false );
        service.setDenormalizeOpAttrsEnabled( true );

        // Now we can create as many partitions as we need
        // Create some new partitions named 'foo', 'bar' and 'apache'.
        var fooPartition = addPartition( "foo", "dc=foo,dc=com" );
        var barPartition = addPartition( "bar", "dc=bar,dc=com" );
        var cfldapPartition = addPartition( "cfldap", "o=cfldap" );
        var peoplePartition = addPartition( "people", "ou=people,dc=apache,dc=org" );
        var apachePartition = addPartition( "apache", "dc=apache,dc=org" );

        // Index some attributes on the apache partition
        addIndex( apachePartition, ["objectClass", "ou", "uid"] );

        // And start the service
        service.startup();

        // Inject the foo root entry if it does not already exist
        try
        {
            service.getAdminSession().lookup( fooPartition.getSuffixDn() );
        }
        catch ( any e )
        {
            var dnFoo = jDn.init( strArray(["dc=foo,dc=com"]) );
            var entryFoo = service.newEntry( dnFoo );
            entryFoo.add("objectClass", strArray(["top", "domain", "extensibleObject"]) );
            entryFoo.add( "dc", strArray(["foo"]) );
            service.getAdminSession().add( entryFoo );
        }

        // Inject the bar root entry
        try
        {
            service.getAdminSession().lookup( barPartition.getSuffixDn() );
        }
        catch ( Any e )
        {
            var dnBar = jDn.init( strArray(["dc=bar,dc=com"]) );
            var entryBar = service.newEntry( dnBar );
            entryBar.add( "objectClass", strArray(["top", "domain", "extensibleObject"]) );
            entryBar.add( "dc", strArray(["bar"]) );
            service.getAdminSession().add( entryBar );
        }

        // Inject the apache root entry
        if ( !service.getAdminSession().exists( apachePartition.getSuffixDn() ) )
        {
            var dnApache = jDn.init( strArray(["dc=Apache,dc=Org"]) );
            var entryApache = service.newEntry( dnApache );
            entryApache.add( "objectClass", strArray(["top", "domain", "extensibleObject"]) );
            entryApache.add( "dc", strArray(["Apache"]) );
            service.getAdminSession().add( entryApache );
        }

        // Inject some other stuff
        if ( !service.getAdminSession().exists( cfldapPartition.getSuffixDn() ) )
        {
            var dnApache = jDn.init( strArray(["o=cfldap"]) );
            var entryApache = service.newEntry( dnApache );
            entryApache.add( "objectClass", strArray(["top", "organization"]) );
            entryApache.add( "o", strArray(["cfldap"]) );
            service.getAdminSession().add( entryApache );
        }
        if ( !service.getAdminSession().exists( peoplePartition.getSuffixDn() ) )
        {
            var dnApache = jDn.init( strArray(["ou=people,dc=apache,dc=org"]) );
            var entryApache = service.newEntry( dnApache );
            entryApache.add( "objectClass", strArray(["top", "organizationalUnit"]) );
            entryApache.add( "ou", strArray(["People"]) );
            entryApache.add( "description", strArray(["People in organization"]) );
            service.getAdminSession().add( entryApache );
        }
        // We are all done !
    }

    void function setAdminPassword(password) {
		var modList = jArrayList.init();
        var dnApache = jDn.init( strArray(["uid=admin,ou=system"]) );
        var entryApache = service.newEntry( dnApache );
        entryApache.add( "userPassword", strArray([password]) );
        modList.add( jDefaultModification.init( jModificationOperation.REPLACE_ATTRIBUTE, entryApache.get("userPassword") ) );
        service.getAdminSession().modify( entryApache.getDn(), modList );
        return;
    }


    /**
     * starts the LdapServer
     *
     * @throws Exception
     */
    void function start(port=10389, enableSSL=true,allowAnonymousAccess=false, ldifDirectory=""){
    	if(ldifDirectory=="") {
	        workDir = jFile.init( getDirectoryFromPath(getMetadata(this).path) & "/server-ldif" );
    	} else {
	        workDir = jFile.init( ldifDirectory );
    	}
        workDir.mkdirs();
        // Create the server
        if(isNull(service)) {
	        initDirectoryService( workDir );
        }
        service.setAllowAnonymousAccess(allowAnonymousAccess);
        // Read an entry
        var ldap = jLdapCoreSessionConnection.init(service);
        var result = ldap.lookup( jDN.init( strArray(["dc=apache,dc=org"]) ) );
        // And print it if available
        System.out.println( "Found entry : " & result );
        result = ldap.lookup( jDN.init( strArray(["o=cfldap"]) ) );
        // And print it if available
        System.out.println( "Found entry : " & result );

        if(isNull(ldapserver)) {
	        ldapserver = jLdapServer.init();
	        var transport = jTcpTransport.init( javacast("int",port) );
	        transport.setEnableSSL(enableSSL);
	        ldapserver.setTransports( [transport] );
	        ldapserver.setDirectoryService( service );
	        ldapserver.start();
        } else {
        	// throw warning log
        }
    }


    /**
     * stop the LdapServer
     *
     * @throws Exception
     */
    void function stop()
    {
    	if(isNull(service)) {
    		throw(type="cfldapserver.communication.error",message="no running server on this thread");
    	}
        service.shutdown();
        try{
        	ldapserver.stop();
        } catch(any e) {}
        service = javaCast("null","");
        ldapserver = javaCast("null","");

    }

    private function getDirectoryService(){
        service.shutdown();
        ldapserver.stop();
    }

	/**
	 * Access point for this component.  Used for thread context loader wrapping.
	 **/
	function callMethod(methodName, args) {
		variables.switchThreadContextClassLoader = cl.getLoader().switchThreadContextClassLoader;
		return switchThreadContextClassLoader(this.runInThreadContext,arguments,cl.getLoader().getURLClassLoader());
    }

	function runInThreadContext(methodName,  args) {
			var theMethod = this[methodName];
			return theMethod(argumentCollection=args);
		try{
		} catch (any e) {
			try{
				stopServer();
			} catch(any err) {}
			throw(e);
		}
	}

	function strArray(inarray) {
		return javaCast("String[]",inarray);
	}
</cfscript>

	<cffunction name="setRequestTimeout">
		<cfargument name="timeout" required="true" />
		<cfsetting requesttimeout="#timeout#" />
	</cffunction>

</cfcomponent>
