// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get recoverAccount => 'Recuperar cuenta';

  @override
  String get recoveryInstructions =>
      'Introduce tu frase de recuperación de 12 palabras para recuperar el acceso y establecer una nueva contraseña.';

  @override
  String get mnemonicPhrase => 'Frase de recuperación';

  @override
  String get twoFactorCode => 'Código de doble factor';

  @override
  String get twoFactorSetup => 'Configurar autenticación de doble factor';

  @override
  String get twoFactorSetupIntro =>
      'Escanea el código QR o copia el secreto en tu app de autenticación, después introduce el código de 6 dígitos para confirmar.';

  @override
  String get copySecret => 'Copiar secreto';

  @override
  String get confirm => 'Confirmar';

  @override
  String get sessionLockedTitle => 'Sesión bloqueada';

  @override
  String get sessionLockedSubtitle =>
      'Desbloquea con tu PIN o tu huella para continuar.';

  @override
  String get enterPin => 'Introduce el PIN';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get useBiometrics => 'Usar biometría';

  @override
  String get acceptTerms =>
      'Acepto los términos de servicio y la política de privacidad';

  @override
  String get optional => 'opcional';

  @override
  String get offers => 'Ofertas';

  @override
  String get wallet => 'Monedero';

  @override
  String get messages => 'Mensajes';

  @override
  String get search => 'Buscar';

  @override
  String get profile => 'Perfil';

  @override
  String get buy => 'Comprar';

  @override
  String get sell => 'Vender';

  @override
  String get buying => 'Comprando';

  @override
  String get selling => 'Vendiendo';

  @override
  String get online => 'En línea';

  @override
  String get local => 'Local';

  @override
  String get createOffer => 'Crear oferta';

  @override
  String get newOffer => 'Nueva oferta';

  @override
  String get editOffer => 'Editar oferta';

  @override
  String get offerType => 'Tipo de oferta';

  @override
  String get coin => 'Moneda';

  @override
  String get currency => 'Divisa';

  @override
  String get paymentMethod => 'Método de pago';

  @override
  String get priceEquation => 'Ecuación de precio';

  @override
  String get priceEquationHelp =>
      'Usa \'market\' para seguir el precio en vivo. Ejemplo: market*1.02';

  @override
  String get minAmount => 'Importe mínimo';

  @override
  String get maxAmount => 'Importe máximo';

  @override
  String get country => 'País';

  @override
  String get city => 'Ciudad';

  @override
  String get terms => 'Condiciones';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get noOffersTitle => 'No se encontraron ofertas';

  @override
  String get noOffersHint => 'Prueba otro filtro o crea tu propia oferta.';

  @override
  String get openTrade => 'Abrir trato';

  @override
  String get trade => 'Trato';

  @override
  String get tradeHistory => 'Historial de tratos';

  @override
  String get tradeChat => 'Chat del trato';

  @override
  String get dispute => 'Disputa';

  @override
  String get openDispute => 'Abrir disputa';

  @override
  String get fundEscrow => 'Depositar en escrow';

  @override
  String get markPaymentSent => 'Marcar pago enviado';

  @override
  String get markPaymentReceived => 'Confirmar pago recibido';

  @override
  String get releaseEscrow => 'Liberar escrow';

  @override
  String get balance => 'Saldo';

  @override
  String get depositAddress => 'Dirección de depósito';

  @override
  String get generateNewAddress => 'Generar nueva dirección';

  @override
  String get withdraw => 'Retirar';

  @override
  String get destinationAddress => 'Dirección de destino';

  @override
  String get amount => 'Importe';

  @override
  String get transactionHistory => 'Historial de transacciones';

  @override
  String get noTransactions => 'Aún no hay transacciones';

  @override
  String get send => 'Enviar';

  @override
  String get encryptWithPgp => 'Cifrar con PGP';

  @override
  String get messagePlaceholder => 'Escribe tu mensaje…';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String get noNotifications => 'Estás al día';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get publicProfile => 'Perfil público';

  @override
  String get feedbackScore => 'Puntuación de feedback';

  @override
  String get trades => 'Tratos';

  @override
  String get memberSince => 'Miembro desde';

  @override
  String get lastSeen => 'Última vez visto';

  @override
  String get trustLevel => 'Nivel de confianza';

  @override
  String get languages => 'Idiomas';

  @override
  String get savePgpKey => 'Guardar clave PGP';

  @override
  String get adminPanel => 'Panel de administración';

  @override
  String get users => 'Usuarios';

  @override
  String get disputes => 'Disputas';

  @override
  String get moderation => 'Moderación';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get ban => 'Banear';

  @override
  String get warn => 'Advertir';

  @override
  String get verify => 'Verificar';

  @override
  String get search_hint => 'Buscar ofertas por moneda, divisa o país';

  @override
  String get filter => 'Filtrar';

  @override
  String get sortByPrice => 'Ordenar por precio';

  @override
  String get sortByReputation => 'Ordenar por reputación';

  @override
  String get sortByRecency => 'Ordenar por más recientes';

  @override
  String get loading => 'Cargando…';

  @override
  String get error => 'Algo salió mal';

  @override
  String get retry => 'Reintentar';
}
