package com.beeinventor.keycloak;

import java.util.ArrayList;
import java.util.Collections;
import org.keycloak.provider.ProviderConfigProperty;
import java.NativeArray;
import org.keycloak.models.AuthenticationExecutionModel.AuthenticationExecutionModel_Requirement;
import org.keycloak.models.KeycloakSession;
import org.keycloak.authentication.FormAction;
import org.keycloak.Config.Config_Scope;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.authentication.FormActionFactory;


class WebhookFormActionFactory implements FormActionFactory {
	public static inline final URL = 'url';
	public static inline final AUTH_HEADER = 'auth-header';
	public static inline final PAYLOAD_MAPPINGS = 'payload-mappings';
	public static inline final ERROR_MESSAGE = 'error-message';
	
	public function new() {}
	
	public function getConfigProperties():java.util.List<ProviderConfigProperty> {
		final list = new ArrayList();

		inline function add(o, ?postprocess) {
			final property = new ProviderConfigProperty(o.name, o.label, o.helpText, o.type, o.defaultValue, o.secret);
			if (postprocess != null)
				postprocess(property);
			return list.add(property);
		}


		add({
			name: URL,
			label: 'Webhook URL',
			helpText: 'This plugin will POST to this URL with a JSON payload. Result status code of 2XX is considered succcess. Otherwise the response payload can be a JSON with a "message" field to be used as the error message (locale key) shown in the registration form',
			type: ProviderConfigProperty.STRING_TYPE,
			defaultValue: '',
			secret: false,
		});

		add({
			name: AUTH_HEADER,
			label: 'Authorization Header',
			helpText: 'Optional. Example: "Bearer MyToken"',
			type: ProviderConfigProperty.STRING_TYPE,
			defaultValue: '',
			secret: true,
		});

		add({
			name: PAYLOAD_MAPPINGS,
			label: 'Payload Mappings',
			helpText: 'Form fields to be included in the JSON payload',
			type: ProviderConfigProperty.MULTIVALUED_STRING_TYPE,
			defaultValue: null,
			secret: false,
		});

		add({
			name: ERROR_MESSAGE,
			label: 'Error Message',
			helpText: 'Default error message (locale key) to show when webhook invocation failed',
			type: ProviderConfigProperty.STRING_TYPE,
			defaultValue: 'registrationNotAllowedMessage',
			secret: false,
		});

		return list;
	}

	public function getHelpText():String {
		return 'Webhook Form Action';
	}

	public function getDisplayType():String {
		return 'Webhook';
	}

	public function getReferenceCategory():String {
		return 'webhook';
	}

	public function getRequirementChoices():NativeArray<AuthenticationExecutionModel_Requirement> {
		return java.NativeArray.make(AuthenticationExecutionModel_Requirement.REQUIRED, AuthenticationExecutionModel_Requirement.DISABLED);
	}

	public function isConfigurable():Bool {
		return true;
	}

	public function isUserSetupAllowed():Bool {
		return true;
	}

	public function close() {}

	public function create(session:KeycloakSession):FormAction {
		return new WebhookFormAction(session);
	}

	public function getId():String {
		return 'registration-webhook';
	}

	public function init(param1:Config_Scope) {}

	public function order():Int {
		return 0;
	}

	public function postInit(param1:KeycloakSessionFactory) {}
}