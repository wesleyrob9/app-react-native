class UserModel {
  final int id;
  final String nome;
  final String? apelido;
  final String email;
  final String username;
  final String? posicaoPrincipal;
  final String? posicaoSecundaria;
  final String? fotoUrl;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.nome,
    this.apelido,
    required this.email,
    required this.username,
    this.posicaoPrincipal,
    this.posicaoSecundaria,
    this.fotoUrl,
    this.avatar,
  });

  String get nomeExibicao => apelido ?? nome;

  UserModel copyWith({
    String? nome,
    String? apelido,
    bool clearApelido = false,
    String? email,
    String? username,
    String? posicaoPrincipal,
    bool clearPosicao = false,
    String? posicaoSecundaria,
    bool clearPosicaoSec = false,
    String? fotoUrl,
    bool clearFoto = false,
    String? avatar,
    bool clearAvatar = false,
  }) => UserModel(
    id: id,
    nome: nome ?? this.nome,
    apelido: clearApelido ? null : (apelido ?? this.apelido),
    email: email ?? this.email,
    username: username ?? this.username,
    posicaoPrincipal: clearPosicao ? null : (posicaoPrincipal ?? this.posicaoPrincipal),
    posicaoSecundaria: clearPosicaoSec ? null : (posicaoSecundaria ?? this.posicaoSecundaria),
    fotoUrl: clearFoto ? null : (fotoUrl ?? this.fotoUrl),
    avatar: clearAvatar ? null : (avatar ?? this.avatar),
  );
}
