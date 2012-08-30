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
		jServerDNConstants = classLoader.create("org.apache.directory.server.constants.ServerDNConstants");
		jDefaultDirectoryService = classLoader.create("org.apache.directory.server.core.DefaultDirectoryService");
		jDirectoryService = classLoader.create("org.apache.directory.server.core.DirectoryService");
		jPartition = classLoader.create("org.apache.directory.server.core.partition.Partition");
		jJdbmIndex = classLoader.create("org.apache.directory.server.core.partition.impl.btree.jdbm.JdbmIndex");
		jJdbmPartition = classLoader.create("org.apache.directory.server.core.partition.impl.btree.jdbm.JdbmPartition");
		jLdifPartition = classLoader.create("org.apache.directory.server.core.partition.ldif.LdifPartition");
		jSchemaPartition = classLoader.create("org.apache.directory.server.core.schema.SchemaPartition");
		jLdapServer = classLoader.create("org.apache.directory.server.ldap.LdapServer");
		jTcpTransport = classLoader.create("org.apache.directory.server.protocol.shared.transport.TcpTransport");
		jIndex = classLoader.create("org.apache.directory.server.xdbm.Index");
		jEntry = classLoader.create("org.apache.directory.shared.ldap.entry.Entry");
		jServerEntry = classLoader.create("org.apache.directory.shared.ldap.entry.ServerEntry");
		jLdapException = classLoader.create("org.apache.directory.shared.ldap.exception.LdapException");
		jDN = classLoader.create("org.apache.directory.shared.ldap.name.DN");
		jSchemaManager = classLoader.create("org.apache.directory.shared.ldap.schema.SchemaManager");
		jSchemaLdifExtractor = classLoader.create("org.apache.directory.shared.ldap.schema.ldif.extractor.SchemaLdifExtractor");
		jDefaultSchemaLdifExtractor = classLoader.create("org.apache.directory.shared.ldap.schema.ldif.extractor.impl.DefaultSchemaLdifExtractor");
		jLdifSchemaLoader = classLoader.create("org.apache.directory.shared.ldap.schema.loader.ldif.LdifSchemaLoader");
		jJarLdifSchemaLoader = classLoader.create("org.apache.directory.shared.ldap.schema.loader.ldif.JarLdifSchemaLoader");
		jDefaultSchemaManager = classLoader.create("org.apache.directory.shared.ldap.schema.manager.impl.DefaultSchemaManager");
		jSchemaLoader = classLoader.create("org.apache.directory.shared.ldap.schema.registries.SchemaLoader");
		jBasicConfigurator = classLoader.create("org.apache.log4j.BasicConfigurator");
		jBasicConfigurator.configure();
		jThread.currentThread().setContextClassLoader(cTL);
		return this;
	}

    private function addPartition( String partitionId, String partitionDn )
    {
        var partition = jJdbmPartition.init();
        partition.setId( partitionId );
        partition.setPartitionDir(jFile.init( service.getWorkingDirectory(), partitionId ) );
        partition.setSuffix( partitionDn );
        service.addPartition( partition );
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
        var schemaPartition = service.getSchemaService().getSchemaPartition();

        // Init the LdifPartition
        var ldifPartition = jLdifPartition.init();
        var workingDirectory = service.getWorkingDirectory().getPath();
        ldifPartition.setWorkingDirectory( workingDirectory & "/schema" );
        var schemaJarPath = getDirectoryFromPath(getMetadata(this).path) & "lib/shared-ldap-schema-0.9.19.jar";
        system.setProperty("log4j.debug","true");
        system.setProperty("schema.resource.location",schemaJarPath);

        // Extract the schema on disk (a brand new one) and load the registries
        var schemaRepository = jFile.init( workingDirectory, "schema" );
        var extractor = jDefaultSchemaLdifExtractor.init( jFile.init( workingDirectory ) );
        extractor.extractOrCopy( true );
        schemaPartition.setWrappedPartition( ldifPartition );

        //var loader = jLdifSchemaLoader.init( schemaRepository );
        var loader = jJarLdifSchemaLoader.init();
        var schemaManager = jDefaultSchemaManager.init( loader );
        service.setSchemaManager( schemaManager );

        // We have to load the schema now, otherwise we won't be able
        // to initialize the Partitions, as we won't be able to parse
        // and normalize their suffix DN
        schemaManager.loadAllEnabled();

        schemaPartition.setSchemaManager( schemaManager );

        var errors = schemaManager.getErrors();

        if ( errors.size() != 0 )
        {
            throw( "Schema load failed : " & toString(errors) );
        }

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
        service.setWorkingDirectory( workDir );

        // first load the schema
        initSchemaPartition();

        // then the system partition
        // this is a MANDATORY partition
        var systemPartition = addPartition( "system", jServerDNConstants.SYSTEM_DN );
        service.setSystemPartition( systemPartition );

        // Disable the ChangeLog system
        service.getChangeLog().setEnabled( false );
        service.setDenormalizeOpAttrsEnabled( true );

        // Now we can create as many partitions as we need
        // Create some new partitions named 'foo', 'bar' and 'apache'.
        var fooPartition = addPartition( "foo", "dc=foo,dc=com" );
        var barPartition = addPartition( "bar", "dc=bar,dc=com" );
        var apachePartition = addPartition( "apache", "dc=apache,dc=org" );

        // Index some attributes on the apache partition
        addIndex( apachePartition, ["objectClass", "ou", "uid"] );

        // And start the service
        service.startup();
        request.debug("REALLY?");

        // Inject the foo root entry if it does not already exist
        try
        {
            service.getAdminSession().lookup( fooPartition.getSuffixDn() );
        }
        catch ( any e )
        {
            var dnFoo = jDN.init( "dc=foo,dc=com" );
            var entryFoo = service.newEntry( dnFoo );
            entryFoo.add( "objectClass", "top", "domain", "extensibleObject" );
            entryFoo.add( "dc", "foo" );
            service.getAdminSession().add( entryFoo );
        }

        // Inject the bar root entry
        try
        {
            service.getAdminSession().lookup( barPartition.getSuffixDn() );
        }
        catch ( any e )
        {
            var dnBar = jDN.init( "dc=bar,dc=com" );
            var entryBar = service.newEntry( dnBar );
            entryBar.add( "objectClass", "top", "domain", "extensibleObject" );
            entryBar.add( "dc", "bar" );
            service.getAdminSession().add( entryBar );
        }

        // Inject the apache root entry
        if ( !service.getAdminSession().exists( apachePartition.getSuffixDn() ) )
        {
            var dnApache = jDN.init( "dc=Apache,dc=Org" );
            var entryApache = service.newEntry( dnApache );
            entryApache.add( "objectClass", "top", "domain", "extensibleObject" );
            entryApache.add( "dc", "Apache" );
            service.getAdminSession().add( entryApache );
        }

        // We are all done !
    }


    /**
     * Creates a new instance of EmbeddedADS. It initializes the directory service.
     *
     * @throws Exception If something went wrong
     */
    public function EmbeddedADSVer157( workDir )
    {
        initDirectoryService( workDir );
    }


    /**
     * starts the LdapServer
     *
     * @throws Exception
     */
    public void function startServer()
    {
        ldapserver = jLdapServer.init();
        var serverPort = 10389;
        ldapserver.setTransports( jTcpTransport.init( serverPort ) );
        ldapserver.setDirectoryService( service );

        ldapserver.start();
    }


    /**
     * stop the LdapServer
     *
     * @throws Exception
     */
    public void function stopServer()
    {
        ldapserver.stop();
        service.shutdown();
    }


    /**
     * Main class.
     *
     * @param args Not used.
     */
    public void function main( )
    {
        //var workDir = jFile.init( System.getProperty( "java.io.tmpdir" ) & "/server-work" );
        var workDir = jFile.init( getDirectoryFromPath(getMetadata(this).path) & "/server-work" );
        workDir.mkdirs();

        // Create the server
        var ads = EmbeddedADSVer157( workDir );

        // Read an entry
        var result = ads.service.getAdminSession().lookup( jDN.init( "dc=apache,dc=org" ) );

        // And print it if available
        System.out.println( "Found entry : " & result );

        // optionally we can start a server too
        ads.startServer();
    }

	function onMissingMethod() {
		var jThread = classLoader.create("java.lang.Thread");
		var cTL = jThread.currentThread().getContextClassLoader();
		jThread.currentThread().setContextClassLoader(classLoader.GETLOADER().getURLClassLoader());
		try{
			return main();
		} catch (any e) {
			request.debug(e);
			jThread.currentThread().setContextClassLoader(cTL);
			throw(e);
		}
		jThread.currentThread().setContextClassLoader(cTL);
	}
}