swagger_config = {
    'headers': [],
    'specs': [
        {
            'endpoint': 'apispec',
            'route': '/api/docs/apispec.json',
            'rule_filter': lambda rule: True,
            'model_filter': lambda tag: True,
        }
    ],
    'static_url_path': '/flasgger_static',
    'swagger_ui': True,
    'specs_route': '/api/docs/',
}

swagger_template = {
    'swagger': '2.0',
    'info': {
        'title': 'App Flutter - API',
        'description': 'Documentação da API do aplicativo de estudo Flutter.',
        'version': '1.0.0',
    },
    'basePath': '/',
    'schemes': ['http', 'https'],
    'securityDefinitions': {
        'Bearer': {
            'type': 'apiKey',
            'name': 'Authorization',
            'in': 'header',
            'description': "Informe o token no formato: Bearer <token>",
        }
    },
}
