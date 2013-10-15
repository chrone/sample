package com.chrone.util;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Properties;

import org.apache.commons.lang.ObjectUtils;

public class Props {

	private final String name;

	private final Properties properties;

	protected Props(String name, Properties properties) {
		this.name = name;
		this.properties = properties;
	}

	public String getString(String key) {
		return getString(key, null);
	}

	public String getString(String key, String defaultValue) {
		return properties.getProperty(key, defaultValue);
	}

	public List<String> getStringList(String key) {
		List<String> emptyList = Collections.emptyList();
		return getStringList(key, emptyList);
	}

	public List<String> getStringList(String key, List<String> defaultValue) {
		List<String> results = defaultValue;
		String s = ObjectUtils.toString(properties.get(key), null);
		if (s != null) {
			results = new ArrayList<String>();
			for (String part : s.split(",")) {
				results.add(part.trim());
			}
		}
		return results;
	}

	public Boolean getBoolean(String key) {
		return getBoolean(key, false);
	}

	public Boolean getBoolean(String key, Boolean defaultValue) {
		String s = ObjectUtils.toString(properties.get(key), null);
		return ((s != null) ? Boolean.valueOf(s) : defaultValue);
	}

	public Double getDouble(String key) {
		return getDouble(key, null);
	}

	public Double getDouble(String key, Double defaultValue) {
		String s = ObjectUtils.toString(properties.get(key), null);
		return ((s != null) ? Double.valueOf(s) : defaultValue);
	}

	public Integer getInteger(String key) {
		return getInteger(key, null);
	}

	public Integer getInteger(String key, Integer defaultValue) {
		String s = ObjectUtils.toString(properties.get(key), null);
		return ((s != null) ? Integer.valueOf(s) : defaultValue);
	}

	public Long getLong(String key) {
		return getLong(key, null);
	}

	public Long getLong(String key, Long defaultValue) {
		String s = ObjectUtils.toString(properties.get(key), null);
		return ((s != null) ? Long.valueOf(s) : defaultValue);
	}

	public Properties toProperties() {
		Properties p = new Properties();
		p.putAll(properties);
		return p;
	}

	@Override
	public String toString() {
		return String.format("Props{name=%s}{size=%d}", name, properties.size());
	}

}
