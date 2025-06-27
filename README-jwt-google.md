# Desarrollo de los cambios

paso a paso detallado para implementar login JWT, registro de usuario y recuperación de contraseña por email en tu proyecto Django REST con Poetry, usando los estándares actuales y paquetes recomendados:

## 1. Instala los paquetes necesarios
Con Poetry:

```bash
poetry add djangorestframework djangorestframework-simplejwt django-rest-passwordreset
```

## 2. Modifica settings.py
Añade las apps necesarias:

```python
INSTALLED_APPS = [
    # ...otras apps
    'rest_framework',
    'rest_framework_simplejwt',
    'django_rest_passwordreset',
    'users',  # tu app de usuarios
]
```
Configura la autenticación JWT:

```python
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}
```
(Opcional) Personaliza los tiempos de vida de los tokens:

```python
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```
## 3. Modifica urls.py del proyecto
Agrega los endpoints JWT y de password reset:

```python
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenObtainPairView, TokenRefreshView, TokenVerifyView
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),  # tus endpoints de usuario
    # JWT endpoints
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    # Password reset endpoints
    path('api/password_reset/', include('django_rest_passwordreset.urls', namespace='password_reset')),
]
```
## 4. Crea o modifica los siguientes archivos en tu app users
a) users/serializers.py
```python
from rest_framework import serializers
from .models import User

class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('email', 'password', 'role')
    
    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user
```
b) users/views.py
```python
from rest_framework import generics, permissions
from .models import User
from .serializers import UserRegisterSerializer

class UserRegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]
c) users/urls.py
python
from django.urls import path
from .views import UserRegisterView

urlpatterns = [
    path('register/', UserRegisterView.as_view(), name='user-register'),
]
```
## 5. Configura el envío de emails para password reset
En tu settings.py, asegúrate de tener configurado el backend de email, por ejemplo para desarrollo:

```python
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
DEFAULT_FROM_EMAIL = 'noreply@tudominio.com'
```
Para producción, usa SMTP.

## 6. Personaliza el email de recuperación (opcional)
Crea las plantillas:
```
templates/email/user_reset_password.html

templates/email/user_reset_password.txt
```
Puedes personalizar el contenido y el enlace de recuperación según la documentación de [django-rest-passwordreset].

## 7. (Opcional) Añade el handler de señal para enviar el email
En users/signals.py (y asegúrate de importarlo en apps.py o ready()):

```python
from django.core.mail import EmailMultiAlternatives
from django.dispatch import receiver
from django.template.loader import render_to_string
from django.urls import reverse
from django_rest_passwordreset.signals import reset_password_token_created

@receiver(reset_password_token_created)
def password_reset_token_created(sender, instance, reset_password_token, *args, **kwargs):
    context = {
        'current_user': reset_password_token.user,
        'username': reset_password_token.user.email,
        'email': reset_password_token.user.email,
        'reset_password_url': "{}?token={}".format(
            instance.request.build_absolute_uri(reverse('password_reset:reset-password-confirm')),
            reset_password_token.key
        )
    }
    email_html_message = render_to_string('email/user_reset_password.html', context)
    email_plaintext_message = render_to_string('email/user_reset_password.txt', context)
    msg = EmailMultiAlternatives(
        "Password Reset for Your Account",
        email_plaintext_message,
        "noreply@tudominio.com",
        [reset_password_token.user.email]
    )
    msg.attach_alternative(email_html_message, "text/html")
    msg.send()
```
## 8. Resumen de endpoints disponibles
| Endpoint	| Método	| Descripción |
|-------------------------|--------|--------------------------------------------------|
|/api/users/register/	|POST|	Registro de usuario|
|/api/token/	|POST|	Login, devuelve access y refresh JWT|
|/api/token/refresh/	|POST|	Refresca el token JWT|
|/api/token/verify/|	POST	|Verifica la validez de un token JWT|
|/api/password_reset/	|POST	|Solicita email de recuperación de contraseña|
|/api/password_reset/confirm/|	POST|	Confirma el token y cambia la contraseña|

## 9. Prueba el flujo
Registro: POST a /api/users/register/ con email, password y role.

Login JWT: POST a /api/token/ con email y password.

Recuperar contraseña: POST a /api/password_reset/ con el email del usuario.

Verifica en la consola el enlace de recuperación (si usas console.EmailBackend).