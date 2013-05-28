module oauth2.oauth_utils;

import std.stdio;
import std.array;
import std.string;
import std.json;
import std.exception;

/**
 * A simple struct to hold necessary data about
 * different oauth2 providers.
 */
struct OAuthProvider {
	string auth_endpoint;
	string token_endpoint;
	string resource_endpoint;

	string client_id;
	string client_secret;
	string redirect_uri;

	string token_state;

	/**
	 * Save the object to the specified handler.
	 */
	public void persist(OAuthSessionHandler handler) {
		handler
				.put(0, auth_endpoint)
				.put(1, token_endpoint)
				.put(2, resource_endpoint)

				.put(3, client_id)
				.put(4, client_secret)
				.put(5, redirect_uri)

				.put(6, token_state)
				.commit();
	}

	/**
	 * Defrost an object in the sessionhandler.
	 */
	public static OAuthProvider defrost(OAuthSessionHandler handler) {
		
		OAuthProvider provider = {
			handler.get(0),
			handler.get(1),
			handler.get(2),
					
			handler.get(3),
			handler.get(4),
			handler.get(5),
					
			handler.get(6)
		};

		return provider;
	}
}


/**
 * Interface to implement custom session handlers.
 * The handler must be able to persist data between
 * calls to the oauth library.
 */
interface OAuthSessionHandler {

	/**
	 * Add a record to the session, or throw. Value may be null.
	 * Returns itself. 
	 */
	public OAuthSessionHandler put(int key, string value);

	/**
	 * Indicate that a series of modifications are done.
	 */
	public void commit();

	/**
	 * Get a record, or null if not exists;
	 */
	public string get(int key);

	/**
	 * Remove a record. Silent if the record doesn't exist.
	 */
	public void remove(int key);

}

/**
 * Represents the standard (successful) response from a token
 * enpoint. Currently, id_token is not implemented as no libraries
 * to decrypt JWE exist for D.
 */
struct OAuthTokenRequestResponse {

	string access_token;
	ulong expires_in;
	string id_token;


	this(string response) {
		JSONValue root = parseJSON(response);
		enforce(root.type == JSON_TYPE.OBJECT, "Unexpected response");

		access_token = root["access_token"].str;
		expires_in = root["expires_in"].uinteger;

	}
}


/**
 * Parse an url and return the parameters as a map.
 */
public string[string] parseUrlForParams(string url) {
	string[string] params;

	auto param_split = url.lastIndexOf("?");
	string strParams = url[param_split + 1.. $];
	size_t size = strParams.sizeof;

	string[] pairs = strParams.split("&");

	foreach(string pair; pairs) {
		auto eq_pos = pair.indexOf('=');
		params[pair[0 .. eq_pos]] = pair[eq_pos+1 .. $];
	}

	return params;
}



/**
 * This is a simple implementation of a session handler.
 * This should only be used for testing.
 */
class MemorySessionHandler : OAuthSessionHandler {
	private string[int] session;
	
	public OAuthSessionHandler put(int key, string value) {
		session[key] = value;
		return this;
	}
	
	public void commit() {
		//PASS
	}
	
	public string get(int key) {
		
		if(key in session)
			return session[key];
		return null;
	}
	
	public void remove(int key) {
		session.remove(key);
	}
	void print() {
		writeln(session);
	}
}










unittest {
	const string CLIENT_ID = "fff";



	/***************************
	OAuth provider
	***************************/
	OAuthProvider provider = {
		client_id: CLIENT_ID,
		auth_endpoint: "somestring"
	};

	auto session = new MemorySessionHandler;

	assert(provider.client_id == CLIENT_ID);

	provider.persist(session);
	OAuthProvider newprovider = OAuthProvider.defrost(session);

	assert(provider.client_id == newprovider.client_id);
	assert(provider.client_secret == newprovider.client_secret);
	assert(provider.auth_endpoint == newprovider.auth_endpoint);


	/***************************
	parse url
	***************************/
	string url = "http://example.net/fdd.pfp?user=mats&oers=3";
	auto params = parseUrlForParams(url);

	assert(params["user"] == "mats");
	assert(params["oers"] == "3");
	assert(params.length == 2);


}












		