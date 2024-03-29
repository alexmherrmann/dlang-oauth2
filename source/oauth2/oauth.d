module oauth2.oauth;

import std.stdio;
import oauth2.oauth_utils;
import std.digest.md;
import std.random;
import std.uuid;
import std.array;
import std.conv : to;

version (VibeExist) {
	import vibe.http.client, vibe.http.common;
} else {
	import std.net.curl;
}


/** Callback from step 2 */
alias void delegate (OAuthTokenRequestResponse) Callback;



/**
 * OAuth2 implementation for D.
 * Read the comment for this(), it's important.
 */
class OAuth
{
	private OAuthProvider provider;

	/**
	 * OAuth is stateful. Therefore you must be careful
	 * about exactly which OAuthProvider you put in here.
	 *   When the user first initiates the OAuth transaction,
	 * just insert the appropriate provider as defined in
	 * providers.d.
	 *   When the user is coming back from the provider,
	 * you must insert the same object into this constructor
	 * in order to mantain state. OAuthProvider supplies the
	 * handy persist() and defrost() methods which enables
	 * you to save the objects somewhere.
	 */
	this(ref OAuthProvider p)
	in {
		assert(p.auth_endpoint !is null);
		assert(p.client_id !is null);
		assert(p.client_secret !is null);
		assert(p.token_endpoint !is null);
		assert(p.redirect_uri !is null);

	} body {
		provider = p;

		if(provider.token_state is null)
			createStateToken();
	}

	/**
	 * Generate a random state token and attach it to the provider.
	 */
	private string createStateToken() {
		string token = randomUUID().toString();

		provider.token_state = token;
		return token;
	}

	/**
	 * Generate the post data for a access token request.
	 */
	private string generateAccessTokenRequestData(string code) {
		return join([
		         "code=",
		         code,
		         "&client_id=",
		         provider.client_id,
		         "&client_secret=",
		         provider.client_secret,
		         "&redirect_uri=",
		         provider.redirect_uri,
		         "&grant_type=authorization_code"
		         ],"");
	}

	/**
	 * Get the response from the supplied post data
	 */
	protected void performHttpPost(string url, string post_data, ulong delegate(ubyte[]) callback) {
		version(VibeExist) {
			auto cres = requestHTTP(url, (creq) {
				creq.method = HttpMethod.POST;
				creq.headers["Content-Type"] = "application/x-www-form-urlencoded";
			});

			callback(cast(string) cres.bodyReader.readAll());

		} else {
			auto client = HTTP(url);
			
			client.method = HTTP.Method.post;
			client.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
			client.postData(post_data);
			client.onReceive(callback);
			client.perform();

		}
	}

	/**
	 * STEP 1:
	 * Redirect the user to the URL generated by the following method.
	 * Saves the generated tokens to the sessionhandler.
	 */
	public string getAuthenticationRequestURL(OAuthSessionHandler handler) {
		string url = "%s?client_id=%s&response_type=code&scope=openid%20email&redirect_uri=%S&state=%s";
		
		url = join([
		            provider.auth_endpoint,
		            "?client_id=",
		            provider.client_id,
		            "&response_type=code&scope=openid%20email&redirect_uri=",
		            provider.redirect_uri,
		            "&state=",
		            provider.token_state]);


		provider.persist(handler);

		return url;

	}

	/**
	 * STEP 2:
	 * Confirm response and request access token.
	 * The callback is called with a OAuthTokenRequestResponse if
	 * successful.
	 */
	public void handleAuthenticationResponse(string url, Callback callback) {
		string[string] params = parseUrlForParams(url);

		string state = params["state"];
		string code = params["code"];

		if(state != provider.token_state)
			throw new Exception("Illegal token");

		string post_data = generateAccessTokenRequestData(code);
		debug writeln(post_data);

		try {

			performHttpPost(provider.token_endpoint, post_data, (ubyte[] data) { 
				auto response = OAuthTokenRequestResponse(cast(string) data);
				callback(response);
				return data.length;
			});

		} catch (CurlException ex) {
			writeln(ex.msg);
		}
	}
}



unittest {

	import oauth2.providers;
	
	const CLIENT_ID = "129710706774.apps.googleusercontent.com";
	const CLIENT_SECRET = "FUm-wHtdPg8Nl6FbLYlzkAS9";
	const REDIRECT = "http://localhost/oauth";
	
	OAuthProvider google = ProviderPresets.googleProvider(CLIENT_ID, CLIENT_SECRET, REDIRECT);
	OAuth auth = new OAuth(google);

	MemorySessionHandler handler = new MemorySessionHandler;
	string url = auth.getAuthenticationRequestURL(handler);
	writeln(url);

	/** The code must be entered manually */
	writeln("Enter the url redirected to");
	string response_url = stdin.readln();

	auth.handleAuthenticationResponse(response_url, (OAuthTokenRequestResponse res) {
		writeln(res.access_token);
	});
	
}
	

	
		