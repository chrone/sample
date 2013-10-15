package com.chrone.util;

import java.io.InputStream;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PropsFactory {

	private static final Logger log = LoggerFactory.getLogger(PropsFactory.class);

	private static final ConcurrentHashMap<String, Props> propsMap = new ConcurrentHashMap<String, Props>();

	private static final String DEFAULT_PROPERTIES_NAME = "/eb-web-java";

	public static Props get() {
		return get(PropsFactory.class, DEFAULT_PROPERTIES_NAME, false);
	}

	public static Props get(boolean includeSystemProperties) {
		return get(PropsFactory.class, DEFAULT_PROPERTIES_NAME, includeSystemProperties);
	}

	public static Props get(String name) {
		return get(PropsFactory.class, name, false);
	}

	public static Props get(Class<?> referenceClass, String name, boolean includeSystemProperties) {
		if (!propsMap.containsKey(name)) {
			Properties combinedProperties = new Properties();
//			Properties properties = new Properties();
//			combinedProperties.putAll(readProperties(referenceClass, String.format("%s-default.properties", name)));
			combinedProperties.putAll(readProperties(referenceClass, String.format("%s.properties", name)));
			if (includeSystemProperties) {
				combinedProperties.putAll(System.getProperties());
			}
			Props newProps = new Props(name, combinedProperties);
			log.debug("Constructed new props: {}", newProps);
			propsMap.putIfAbsent(name, newProps);
		}
		Props props = propsMap.get(name);
		log.debug("get({}) returning {}", name, props);
		return props;
	}

	private static Properties readProperties(Class<?> referenceClass, String path) {
		Properties p = new Properties();
		InputStream is = null;
		try {
			is = referenceClass.getResourceAsStream(path);
			p.load(is);
		} catch (Throwable t) {
			if (StringUtils.startsWith(path, DEFAULT_PROPERTIES_NAME)) {
				log.warn("No properties file found in classpath: {}", path);
			} else {
				log.debug("No properties file found in classpath: {}", path);
			}
		} finally {
			IOUtils.closeQuietly(is);
		}
		return p;
	}

}
