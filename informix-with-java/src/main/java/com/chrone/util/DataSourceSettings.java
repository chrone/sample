package com.chrone.util;

import java.util.HashMap;
import java.util.Properties;
import java.util.Map.Entry;

import com.jolbox.bonecp.BoneCPConfig;

public class DataSourceSettings {

	private static final HashMap<String, DataSourceSettings> INSTANCES = new HashMap<String, DataSourceSettings>();

	private static final HashMap<String, String> driverClasses = new HashMap<String, String>();

	private static final HashMap<String, HashMap<String, String>> driverDefaultSettings = new HashMap<String, HashMap<String, String>>();

	private final String baseUrl;

	private final String username;

	private final String password;

	private final String driverName;

	private final String driverClass;

	private final HashMap<String, String> driverSettings;

	private final String optionString;

	static {
		init();
	}

	private static void init() {
		Properties props = PropsFactory.get("/datasource").toProperties();
		HashMap<String, HashMap<String, String>> sources = new HashMap<String, HashMap<String, String>>();

		// parse all params
		for (Entry<Object, Object> entry: props.entrySet()) {
			String[] parts = ((String)entry.getKey()).split("[.]");
			if (!sources.containsKey(parts[0])) {
				sources.put(parts[0], new HashMap<String, String>());
			}
			sources.get(parts[0]).put(parts[1], (String)entry.getValue());
		}

		// driver mappings
		driverClasses.putAll(sources.remove("_driver"));

		// driver default settings
		for (Entry<String, String> entry: driverClasses.entrySet()) {
			String sourceName = "_"+entry.getKey();
			if (sources.containsKey(sourceName))
				driverDefaultSettings.put(entry.getKey(), sources.remove(sourceName));
		}

		for (Entry<String, HashMap<String, String>> entry: sources.entrySet()) {
			INSTANCES.put(entry.getKey(), new DataSourceSettings(entry.getValue()));
		}
	}

	public static void reload() {
		INSTANCES.clear();
		driverClasses.clear();
		driverDefaultSettings.clear();
		init();
	}

	// private constructor
	private DataSourceSettings(HashMap<String, String> settings) {
		baseUrl = settings.get("baseurl");
		username = settings.get("username");
		password = settings.get("password");
		driverName = settings.get("driver");
		driverClass = driverClasses.get(driverName);

		driverSettings = new HashMap<String, String>();
		if (driverDefaultSettings.containsKey(driverName))
			driverSettings.putAll(driverDefaultSettings.get(driverName));
		for (Entry<String, String> entry: settings.entrySet()) {
			if (entry.getKey().startsWith("+"))
				driverSettings.put(entry.getKey().substring(1), entry.getValue());
		}

		StringBuilder sb = new StringBuilder();
		for (Entry<String, String> entry: driverSettings.entrySet()) {
			if (sb.length() > 0) sb.append(";");
			sb.append(entry.getKey() + "=" + entry.getValue());
		}
		optionString = sb.toString();
	}

	protected static DataSourceSettings get(String dataSourceName) {
		return INSTANCES.get(dataSourceName);
	}

	protected BoneCPConfig generateBoneCPConfig(String database) {
		BoneCPConfig config = getDefaultBoneCPConfig();
		config.setJdbcUrl( generateJdbcUrl(database) );
		config.setUsername( getUsername() );
		config.setPassword( getPassword() );
		return config;
	}

	protected String generateJdbcUrl(String database) {
		String jdbcUrl = baseUrl + database;
		if (optionString.length() > 0) jdbcUrl += ":" + optionString;
		return jdbcUrl;
	}

	protected String getBaseUrl() {
		return baseUrl;
	}

	protected String getDriverClass() {
		return driverClass;
	}

	protected String getUsername() {
		return username;
	}

	protected String getPassword() {
		return password;
	}

	private static BoneCPConfig getDefaultBoneCPConfig() {
		BoneCPConfig config = new BoneCPConfig();
		config.setMinConnectionsPerPartition(0);
		config.setMaxConnectionsPerPartition(5);
		config.setPartitionCount(3);
		config.setAcquireIncrement(1);
		config.setIdleConnectionTestPeriodInSeconds(60);
		config.setMaxConnectionAgeInSeconds(60);
		return config;
	}

}
