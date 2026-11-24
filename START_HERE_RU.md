# Запуск StayGo

Распакуй архив и открой папку с `pubspec.yaml` в Android Studio.

Для Android открой эмулятор и выполни:

```powershell
flutter pub get
flutter run
```

Для запуска в Chrome на Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_web.ps1
```

Каталог отелей загружается из интернета. Создать аккаунт и войти можно через Profile.
После успешного входа откроется каталог. Кнопка Notes находится вверху справа.
При обновлении существующей папки смотри UPDATE_RU.md.

Фото и маршрут можно сохранить через Journal. Для Chrome разреши камеру и геолокацию.
Для эмулятора в настройках виртуального устройства выбери Webcam0 для Front и Rear.
