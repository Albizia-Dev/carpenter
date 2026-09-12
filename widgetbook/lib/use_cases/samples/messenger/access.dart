import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../../helpers/layout_viewport.dart';

final messengerAccessComponent = WidgetbookComponent(
  name: 'Messenger access',
  useCases: [
    WidgetbookUseCase(
      name: 'Messenger Plus host',
      builder: (context) => layoutViewportPreview(
        context,
        child: CarpenterMessengerHost(
          title: 'Мессенджер+',
          accountLabel: context.knobs.string(
            label: 'Аккаунт оболочки',
            initialValue: 'Александра Константинопольская',
          ),
          problem: context.knobs.boolean(label: 'Ошибка выбора файла')
              ? 'Не удалось добавить файл. Повторите выбор.'
              : null,
          onLogout: () {},
          child: Center(child: CarpenterMessageBubble(message: const CarpenterMessageItem(id: 'imported', author: 'Анна', text: 'Проверьте смету', status: '', attachmentLabels: ['Смета.pdf'], relatedObjectLabel: 'Заказ №42', needAnswer: true), onAttachment: (_) {}, onRelatedObject: () {})),
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => layoutViewportPreview(
        context,
        child: MessengerAccessScenario(
          stage: context.knobs.object.dropdown(
            label: 'Состояние',
            options: CarpenterAccessStage.values,
            labelBuilder: (v) => switch (v) {
              CarpenterAccessStage.credentials => 'Вход',
              CarpenterAccessStage.submitting => 'Отправка формы',
              CarpenterAccessStage.connecting => 'Подключение',
              CarpenterAccessStage.waiting => 'Подготовка аккаунта',
              CarpenterAccessStage.external => 'В браузере',
              CarpenterAccessStage.unavailable => 'Ещё не запущен',
              CarpenterAccessStage.failure => 'Ошибка',
              CarpenterAccessStage.signingOut => 'Выход',
            },
          ),
          browserAccount: context.knobs.boolean(
            label: 'Подтверждение браузерного аккаунта',
          ),
          accountLabel: context.knobs.string(
            label: 'Аккаунт',
            initialValue: 'Александра Константинопольская (alexandra.work)',
          ),
          error: context.knobs.boolean(label: 'Ошибка входа'),
          longText: context.knobs.boolean(label: 'Длинное описание'),
          customTitle: context.knobs.string(label: 'Заголовок'),
          customDescription: context.knobs.string(label: 'Описание'),
          customAction: context.knobs.string(label: 'Основное действие'),
          showCancel: context.knobs.boolean(label: 'Отмена входа'),
          showSecondary: context.knobs.boolean(
            label: 'Дополнительное действие',
            initialValue: true,
          ),
        ),
      ),
    ),
  ],
);

class MessengerAccessScenario extends StatefulWidget {
  const MessengerAccessScenario({
    super.key,
    this.stage = CarpenterAccessStage.credentials,
    this.browserAccount = false,
    this.accountLabel = 'Александра Константинопольская (alexandra.work)',
    this.error = false,
    this.longText = false,
    this.customTitle = '',
    this.customDescription = '',
    this.customAction = '',
    this.showSecondary = true,
    this.showCancel = false,
  });
  final CarpenterAccessStage stage;
  final bool error, longText, browserAccount;
  final String accountLabel;
  final String customTitle, customDescription, customAction;
  final bool showSecondary, showCancel;
  @override
  State<MessengerAccessScenario> createState() =>
      _MessengerAccessScenarioState();
}

class _MessengerAccessScenarioState extends State<MessengerAccessScenario> {
  final identifier = TextEditingController();
  final password = TextEditingController();
  bool visible = false;
  bool submitted = false, cancelled = false;
  @override
  void dispose() {
    identifier.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.browserAccount
        ? CarpenterAccessStage.external
        : widget.stage;
    final form =
        stage == CarpenterAccessStage.credentials ||
        stage == CarpenterAccessStage.submitting;
    final (title, description, action) = switch (stage) {
      CarpenterAccessStage.credentials || CarpenterAccessStage.submitting => (
        'Добро пожаловать',
        'Все рабочие процессы — в одном месте.',
        'Войти',
      ),
      CarpenterAccessStage.connecting => (
        'Подключаемся',
        'Восстанавливаем вашу сессию.',
        'Подождите',
      ),
      CarpenterAccessStage.waiting => (
        'Готовим ваш аккаунт',
        'Доступ подключается автоматически. Повторно регистрироваться не нужно.',
        'Проверить доступ',
      ),
      CarpenterAccessStage.external => (
        'Завершите вход',
        'Продолжите в открывшемся браузере, затем вернитесь в приложение.',
        'Открыть браузер',
      ),
      CarpenterAccessStage.unavailable => (
        'Скоро будем на связи',
        'Мессенджер готовится к запуску. Ваш аккаунт сохранён.',
        'Проверить ещё раз',
      ),
      CarpenterAccessStage.failure => (
        'Не удалось подключиться',
        'Проверьте подключение к интернету и попробуйте ещё раз.',
        'Повторить',
      ),
      CarpenterAccessStage.signingOut => (
        'Завершаем выход',
        'Закрываем активную сессию. Это может занять немного времени.',
        'Подождите',
      ),
    };
    return CarpenterMessengerAccess(
      stage: stage,
      title: cancelled
          ? 'Вход отменён'
          : submitted
          ? 'Действие получено'
          : (widget.customTitle.isEmpty ? title : widget.customTitle),
      description: widget.customDescription.isNotEmpty
          ? widget.customDescription
          : widget.browserAccount
          ? widget.accountLabel
          : widget.longText
          ? '$description Рабочие обсуждения, личные сообщения и звонки останутся в одном месте — на компьютере и телефоне.'
          : description,
      identifier: identifier,
      password: password,
      primaryLabel: widget.customAction.isNotEmpty
          ? widget.customAction
          : widget.browserAccount
          ? 'Продолжить вход'
          : action,
      onPrimary: () => setState(() {
        submitted = true;
        password.clear();
      }),
      errorText: widget.error
          ? 'Неверный логин или пароль. Проверьте данные и попробуйте снова.'
          : null,
      secondaryLabel: widget.browserAccount
          ? 'Войти в другой аккаунт'
          : 'Выйти',
      onSecondary: form || !widget.showSecondary
          ? null
          : () => setState(() => submitted = false),
      cancelLabel: 'Отменить вход',
      onCancel: !widget.showCancel
          ? null
          : () => setState(() {
              cancelled = true;
              identifier.clear();
              password.clear();
            }),
      passwordVisible: visible,
      onPasswordVisibilityChanged: (value) => setState(() => visible = value),
    );
  }
}
