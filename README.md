# Talk
### An iOS application for Chat SDK testing.
<img src="https://github.com/hamed8080/Talk/raw/main/images/icon.png" width="64" height="64">
<br />

<img src="https://github.com/hamed8080/Talk/raw/main/images/main.png"  width="640" height="480">
<br />

## Features
- [x] Testing `Chat` and `Async` SDK.
- [x] Demonstration of Microservice architecture.
- [x] Calling with WebRTC(In progress).

## Building And Running
open the terminal:

```bash
cd talk
chmod +x scripts.sh
./scripts.sh setup
```

## Switching to develop mode
Talk uses Chat SDK and Chat SDK is a modular SDK, to put submodules in development mode run:
```bash
cd talk
./scripts.sh pkg local
```

to get back into the remote mode run:
```bash
cd talk
./scripts.sh pkg remote
```

The best way to work with this script is that you add it as a source to your bash file:
```bash
source path_to/scripts.sh
```

## Registerarion
&ast; Phone number registeration is required for running the app.
<br />
Go to [link](https://accounts.pod.ir/) and register then login only with your phone number.

## Dependency Graph of the whole application and SDKs
<img src="https://github.com/hamed8080/Talk/raw/main/images/dependencies.jpg"  width="256" height="480">
<br />

## [Documentation](https://hamed8080.gitlab.io/chat/documentation/chat/)
For more information about how to use Chat SDK visit [Documentation](https://hamed8080.gitlab.io/chat/documentation/Chat/) 
<br/>

## Contributing to Chat
Please see the [contributing guide](/CONTRIBUTING.md) for more information.
