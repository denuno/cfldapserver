component output="false" persistent="false" {
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

	public function init() {
   		classLoader = new LibraryLoader(getDirectoryFromPath(getMetaData(this).path) & "lib/").init();
		var jThread = classLoader.create("java.lang.Thread");
		var cTL = jThread.currentThread().getContextClassLoader();
		jThread.currentThread().setContextClassLoader(classLoader.GETLOADER().getURLClassLoader());
		system = classLoader.create("java.lang.System");
		jFile = classLoader.create("java.io.File");
		jHashSet = classLoader.create("java.util.HashSet");
		jList = classLoader.create("java.util.List");
		jArrayList = classLoader.create("java.util.ArrayList");

		jLdapConnection = classLoader.create("org.apache.directory.ldap.client.api.LdapConnection");
		jServerDNConstants = classLoader.create("org.apache.directory.server.constants.ServerDNConstants");
		jDefaultDirectoryService = classLoader.create("org.apache.directory.server.core.DefaultDirectoryService");
		jDirectoryService = classLoader.create("org.apache.directory.server.core.api.DirectoryService");
		jInstanceLayout = classLoader.create("org.apache.directory.server.core.api.InstanceLayout");
		jLdapCoreSessionConnection = classLoader.create("org.apache.directory.server.core.api.LdapCoreSessionConnection");
		jPartition = classLoader.create("org.apache.directory.server.core.api.partition.Partition");
		jSchemaPartition = classLoader.create("org.apache.directory.server.core.api.schema.SchemaPartition");
		jJdbmIndex = classLoader.create("org.apache.directory.server.core.partition.impl.btree.jdbm.JdbmIndex");
		jJdbmPartition = classLoader.create("org.apache.directory.server.core.partition.impl.btree.jdbm.JdbmPartition");
		jLdifPartition = classLoader.create("org.apache.directory.server.core.partition.ldif.LdifPartition");
		jLdapServer = classLoader.create("org.apache.directory.server.ldap.LdapServer");
		jTcpTransport = classLoader.create("org.apache.directory.server.protocol.shared.transport.TcpTransport");
		jIndex = classLoader.create("org.apache.directory.server.xdbm.Index");
		jEntry = classLoader.create("org.apache.directory.shared.ldap.model.entry.Entry");
		jLdapException = classLoader.create("org.apache.directory.shared.ldap.model.exception.LdapException");
		jDn = classLoader.create("org.apache.directory.shared.ldap.model.name.Dn");
		jRdn = classLoader.create("org.apache.directory.shared.ldap.model.name.Rdn");
		jSchemaManager = classLoader.create("org.apache.directory.shared.ldap.model.schema.SchemaManager");
		jSchemaLdifExtractor = classLoader.create("org.apache.directory.shared.ldap.schemaextractor.SchemaLdifExtractor");
		jDefaultSchemaLdifExtractor = classLoader.create("org.apache.directory.shared.ldap.schemaextractor.impl.DefaultSchemaLdifExtractor");
		jLdifSchemaLoader = classLoader.create("org.apache.directory.shared.ldap.schemaloader.LdifSchemaLoader");
		jDefaultSchemaManager = classLoader.create("org.apache.directory.shared.ldap.schemamanager.impl.DefaultSchemaManager");

		jDefaultModification = classLoader.create("org.apache.directory.shared.ldap.model.entry.DefaultModification");
		jModificationOperation = classLoader.create("org.apache.directory.shared.ldap.model.entry.ModificationOperation");

		jLog4jPropertyConfigurator = classLoader.create("org.apache.log4j.PropertyConfigurator");
		jLog4jPropertyConfigurator.configure(getDirectoryFromPath(getMetadata(this).path) & "/lib/log4j.properties");
		//jBasicConfigurator = classLoader.create("org.apache.log4j.BasicConfigurator");
		//jBasicConfigurator.configure();
		jThread.currentThread().setContextClassLoader(cTL);
		return this;
	}

    private function addPartition( String partitionId, String partitionDn )
    {
        var partition = jJdbmPartition.init(service.getSchemaManager());
        partition.setId( partitionId );
        partition.setPartitionPath( jFile.init( workDir, partitionId ).toURI() );
        var dn = jDn.init([partitionDn]);
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
    private function addSystemPartition( String partitionId, String partitionDn )
    {
        var partition = jJdbmPartition.init(service.getSchemaManager());
        partition.setId( partitionId );
        partition.setPartitionPath( jFile.init( workDir, partitionId ).toURI() );
        var dn = jDn.init([partitionDn]);
        partition.setSuffixDn( dn );
        return partition;
    }

    /**
     * Add a new set of index on the given attributes
     *
     * @param partition The partition on which we want to add index
     * @param attrs The list of attributes to index
     */
    private void function addIndex( partition, Array attrs )
    {
        // Index some attributes on the apache partition
        indexedAttributes = jHashSet.init();
        for ( attribute in attrs )
        {
            indexedAttributes.add( jJdbmIndex.init( attribute ) );
        }
        partition.setIndexedAttributes( indexedAttributes );
    }


    /**
     * initialize the schema manager and add the schema partition to diectory service
     *
     * @throws Exception if the schema LDIF files are not found on the classpath
     */
    private void function initSchemaPartition()
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
			setting requesttimeout=180;
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
    private void function initDirectoryService( workDir )
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
            var dnFoo = jDn.init( ["dc=foo,dc=com"] );
            var entryFoo = service.newEntry( dnFoo );
            entryFoo.add("objectClass", ["top", "domain", "extensibleObject"] );
            entryFoo.add( "dc", ["foo"] );
            service.getAdminSession().add( entryFoo );
        }

        // Inject the bar root entry
        try
        {
            service.getAdminSession().lookup( barPartition.getSuffixDn() );
        }
        catch ( Any e )
        {
            var dnBar = jDn.init( ["dc=bar,dc=com"] );
            var entryBar = service.newEntry( dnBar );
            entryBar.add( "objectClass", ["top", "domain", "extensibleObject"] );
            entryBar.add( "dc", ["bar"] );
            service.getAdminSession().add( entryBar );
        }

        // Inject the apache root entry
        if ( !service.getAdminSession().exists( apachePartition.getSuffixDn() ) )
        {
            var dnApache = jDn.init( ["dc=Apache,dc=Org"] );
            var entryApache = service.newEntry( dnApache );
            entryApache.add( "objectClass", ["top", "domain", "extensibleObject"] );
            entryApache.add( "dc", ["Apache"] );
            service.getAdminSession().add( entryApache );
        }

        // Inject some other stuff
        if ( !service.getAdminSession().exists( cfldapPartition.getSuffixDn() ) )
        {
            var dnApache = jDn.init( ["o=cfldap"] );
            var entryApache = service.newEntry( dnApache );
            entryApache.add( "objectClass", ["top", "organization"] );
            entryApache.add( "o", ["cfldap"] );
            service.getAdminSession().add( entryApache );
        }
        if ( !service.getAdminSession().exists( peoplePartition.getSuffixDn() ) )
        {
            var dnApache = jDn.init( ["ou=people,dc=apache,dc=org"] );
            var entryApache = service.newEntry( dnApache );
            entryApache.add( "objectClass", ["top", "organizationalUnit"] );
            entryApache.add( "ou", ["People"] );
            entryApache.add( "description", ["People in organization"] );
            service.getAdminSession().add( entryApache );
        }
        // We are all done !
    }

    private void function setAdminPassword(password) {
		var modList = jArrayList.init();
        var dnApache = jDn.init( ["uid=admin,ou=system"] );
        var entryApache = service.newEntry( dnApache );
        entryApache.add( "userPassword", [password] );
        modList.add( jDefaultModification.init( jModificationOperation.REPLACE_ATTRIBUTE, entryApache.get("userPassword") ) );
        service.getAdminSession().modify( entryApache.getDn(), modList );
        return;
    }


    /**
     * starts the LdapServer
     *
     * @throws Exception
     */
    private void function start(port=10389, enableSSL=true,allowAnonymousAccess=false, ldifDirectory=""){
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
        var result = ldap.lookup( jDN.init( ["dc=apache,dc=org"] ) );
        // And print it if available
        System.out.println( "Found entry : " & result );
        result = ldap.lookup( jDN.init( ["o=cfldap"] ) );
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
    private void function stop()
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
	function callMethod(methodName, required args) {
		var jThread = classLoader.create("java.lang.Thread");
		var cTL = jThread.currentThread().getContextClassLoader();
		jThread.currentThread().setContextClassLoader(classLoader.GETLOADER().getURLClassLoader());
		try{
			var theMethod = this[methodName];
			return theMethod(argumentCollection=args);
		} catch (any e) {
			try{
				stopServer();
			} catch(any err) {}
			jThread.currentThread().setContextClassLoader(cTL);
			throw(e);
		}
		jThread.currentThread().setContextClassLoader(cTL);
	}
}