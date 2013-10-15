package com.chrone.util;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jolbox.bonecp.BoneCP;
import com.jolbox.bonecp.BoneCPConfig;

public class DataSourceFactory {

	private static final Logger log = LoggerFactory.getLogger(DataSourceFactory.class);

	private static final ConcurrentHashMap<String, BoneCP> pools = new ConcurrentHashMap<String, BoneCP>();

	/**
	 * Get Connection from ConnectionPool
	 * @param server name of datasource in datasource.properties
	 * @param database database name
	 * @return Connection (leased from ConnectionPool)
	 * @throws SQLException
	 */
	public static Connection getConnection(String server, String database) throws SQLException {
		Connection conn = getConnectionPool(server, database).getConnection();
		// reset Transaction Isolation Level to READ_UNCOMMITTED
		if (conn.getTransactionIsolation() != Connection.TRANSACTION_READ_UNCOMMITTED)
			conn.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
		if (conn.getAutoCommit() != true)
			conn.setAutoCommit(true);
		return conn;
	}

	/**
	 * Get Connection from ConnectionPool
	 * @param database "server/database"
	 * @return Connection (leased from ConnectionPool)
	 * @throws SQLException
	 */
	public static Connection getConnection(String database) throws SQLException {
		String[] parts = database.split("/");
		return getConnection(parts[0], parts[1]);
	}

	/**
	 * Get ConnectionPool
	 * @param database "server/database"
	 * @return BoneCP
	 * @throws SQLException
	 */
	public static BoneCP getConnectionPool(String database) throws SQLException {
		String[] parts = database.split("/");
		return getConnectionPool(parts[0], parts[1]);
	}

	/**
	 * Get ConnectionPool
	 * @param dataSourceName name of datasource in datasource.properties
	 * @param database database name
	 * @return BoneCP
	 * @throws SQLException
	 */
	public static BoneCP getConnectionPool(String dataSourceName, String database) throws SQLException {
		String poolKey = dataSourceName + "/" + database;

		BoneCP bonecp = pools.get(poolKey);
		if (bonecp != null) return bonecp;

		DataSourceSettings source = DataSourceSettings.get(dataSourceName);
		try {
			// load driver
			Class.forName(source.getDriverClass());
		} catch (Exception e) {
			log.error("Failed to load driver: {}", source.getDriverClass());
			throw new RuntimeException("Class not found", e);
		}
		BoneCPConfig config = source.generateBoneCPConfig(database);
		if (pools.putIfAbsent(poolKey, new BoneCP(config)) == null)
				log.info("pool created for {} ({})", poolKey, source.getBaseUrl()+database);

		return pools.get(poolKey);
	}

}
