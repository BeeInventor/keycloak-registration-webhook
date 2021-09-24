package com.beeinventor.keycloak;

import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Json;
import java.lang.Throwable;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import org.keycloak.authentication.FormAction;
import org.keycloak.authentication.FormContext;
import org.keycloak.authentication.ValidationContext;
import org.keycloak.events.Errors;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.models.Constants;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.utils.FormMessage;

class WebhookFormAction implements FormAction {

	final session:KeycloakSession;
	
	public function new(session) {
		this.session = session;
	}
	public function close() {}

	public function buildPage(ctx:FormContext, provider:LoginFormsProvider) {}

	public function configuredFor(session:KeycloakSession, realm:RealmModel, user:UserModel):Bool {
		return true;
	}

	public function requiresUser():Bool {
		return false;
	}

	public function setRequiredActions(session:KeycloakSession, realm:RealmModel, user:UserModel) {}

	public function success(ctx:FormContext) {}

	public function validate(ctx:ValidationContext) {
		final config = ctx.getAuthenticatorConfig().getConfig();
		final formData = ctx.getHttpRequest().getDecodedFormParameters();
		final payload = new DynamicAccess();
		final url = config.get(WebhookFormActionFactory.URL);
		final auth = config.get(WebhookFormActionFactory.AUTH_HEADER);
		final errors = new ArrayList();
		
		for(field in config.get(WebhookFormActionFactory.PAYLOAD_MAPPINGS).split(Constants.CFG_DELIMITER))
			payload[field] = formData.getFirst(field);
		
		try {
			final result = invokeWebhook(url, 'POST', payload, auth);
			final code = result.status;
			
			if(code >= 200 && code < 300) {
				trace('success()');
				ctx.success();
			}
			else {
				trace('Webhook returned code: $code');
				ctx.error(Errors.INVALID_REGISTRATION);
				final message = switch try haxe.Json.parse(result.body.toString()).message catch(_) null {
					case null: config.get(WebhookFormActionFactory.ERROR_MESSAGE);
					case v: v;
				}
				errors.add(new FormMessage(FormMessage.GLOBAL, message, 0));
				ctx.validationError(formData, errors);
				ctx.excludeOtherErrors();
			}
			
		} catch(ex:Throwable) {
			// ex.printStackTrace();
			ctx.error(Errors.INVALID_REGISTRATION);
			errors.add(new FormMessage(FormMessage.GLOBAL, config.get(WebhookFormActionFactory.ERROR_MESSAGE), 0));
			ctx.validationError(formData, errors);
			ctx.excludeOtherErrors();
			
		}
	}
	
	function invokeWebhook(url:String, method:String, payload:Dynamic, ?auth:String) {
		final url = new URL(url);
		final cnx:HttpURLConnection = cast url.openConnection();
		final data = Bytes.ofString(Json.stringify(payload));

		cnx.setRequestMethod(method);
		cnx.setRequestProperty('Content-Type', 'application/json');
		switch auth {
			case null | '': // skip
			case _: cnx.setRequestProperty('Authorization', auth);
		}
		cnx.setDoOutput(true);

		final out = cnx.getOutputStream();
		out.write(data.getData());
		out.flush();
		out.close();

		return {
			status: cnx.getResponseCode(),
			body: {
				final body = cnx.getInputStream();
				final buffer = new BytesBuffer();
				while (true)
					switch body.read() {
						case -1: break;
						case v: buffer.addByte(v);
					}
				buffer.getBytes();
			}
		}
	}
}
