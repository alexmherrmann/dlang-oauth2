module source.providers;

import source.oauth;
import source.oauth_utils;

struct ProviderPresets {

public static:
	OAuthProvider googleProvider(string client_id, string client_secret, string redirect_url) {
		OAuthProvider p = {
			auth_endpoint: "https://accounts.google.com/o/oauth2/auth",
			token_endpoint: "https://accounts.google.com/o/oauth2/token",
			client_id: client_id,

			client_secret: client_secret,
			redirect_uri: redirect_url
		};
		return p;
	}
}