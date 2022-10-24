Welcome to [localize_it], yet another package for localizing your app.

# Motivation

This package is dedicated to everyone who had to localize a whole app from scratch. 
Flutter is awesome, but localizing your app can cause serious pain and demotivation. 

We may have to:

- configure your localization for each project from scratch
- think of a `key` for each String we want to localize
- access `context` everywhere we want to localize
- hire a Translation Service Provider for proper translation 
- ...


Implementing all of this can take extra hours or days of extra work, which can be frustrating because it is also rather simple work but a lot.

Localize_it tries to fix that by doing all the annoying work for you, allowing you
to focus on developing your app and make it globally available.

| Before                                                     | After                                                                         |
| -----------------------------------------------------------| ----------------------------------------------------------------------------- |
| `AppLocalizations.of(context).thisIsAnAnnoyingText`        | `This is so easy`.tr                                                          |

# How to use

## 1. Install

To use [localize_it], you will need your typical [build_runner]/code-generator setup.\
First, install [build_runner] and [localize_it] by adding them to your `pubspec.yaml` file:

For a Flutter project:

```console
flutter pub add localize_it_annotation
flutter pub add --dev build_runner
flutter pub add --dev localize_it
```

For a Dart project:

```console
dart pub add localize_it_annotation
dart pub add --dev build_runner
dart pub add --dev localize_it
```

This installs three packages:

- [build_runner](https://pub.dev/packages/build_runner), the tool to run code-generators
- [localize_it], the code generator
- [localize_it_annotation](https://pub.dev/packages/localize_it_annotation/score), a package containing annotations for [localize_it].

## 2. localize_it x GetX

To get the most out of this package make sure to install [GetX](https://pub.dev/packages/get) as well.
With that you can simply call `.tr` behind every `String` you want to translate. 

This also gives you access to multiple other *utils*. See more on [GetX](https://pub.dev/packages/get#internationalization).

## 3. Setup Config file (with VSCode Extension)

Next Step is to setup a config-file. Writing code by yourself? Haha. 

Lucky for you there is a [VSCode-Extension](https://marketplace.visualstudio.com/items?itemName=DieGlckswurst.localize-it).

After installling it you can simply call `localize_it: Create` anywhere inside your `lib/`. Easy!

## 4. Configure 

| Field                     | Description                                                                   |
| ------------------------- | ----------------------------------------------------------------------------- |
| `baseLanguageCode`        | `String` that expects a lanugage code in **lowercase**.                       |
|                           | Supports all the currently available Source Languages (`source_lang`)         |
|                           | on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/). |
|                           | Defaults to: `'de' (German)`                                                  |
| ------------------------- | ----------------------------------------------------------------------------- |
| `supportedLanguageCodes`  | `List<String` that expects lanugage codes in **lowercase**.                   |
|                           | Should *not* contain `baseLanguageCode`                                       |
|                           | Supports all the currently available Target Languages (`target_lang`)         |
|                           | on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/). |
|                           | Defaults to: `['en' (English), 'es' (Spanish)]`                               |
| ------------------------- | ----------------------------------------------------------------------------- |
| `deepLAuthKey`            | `String` that expects your *DeepL Auth Key*                                   |
|                           | Providing a `deepLAuthKey` enables translation generation                     |
|                           | via the [DeepL API](https://www.deepl.com/de/pro-api?cta=header-pro-api/).    |
|                           | If no key is provided (empty String), all *marked Strings* (end with `.tr`)   |
|                           | in your project will get translated to `'--missing translation--'`.           |
| ------------------------- | ----------------------------------------------------------------------------- |
| `useGetX`                 | If `true` a file called `translation_keys.dart` is created that               |
|                           | maps [supportedLanguageCodes] to their localization-files.                    |
|                           | `translation_keys` can simply be passed to `GetMaterialApp`                   |
|                           | to enable Localization.                                                       |










