# Flutter Campus Navigator

A WIP flutter app that will hopefully one day replace the https://navigator.tu-dresden.de website.

## Features

* Search for rooms
* Display Building Maps & building adresses

It works by using the search api and then scraping the returned HTML document to render the campus navigator view in flutter.

![RoomView](./assets/roomView.png)

## Goals & Non-Goals

This app is supposed to deliver a good user experience for the campus navigator on mobile, therefore perfect feature parity with the website is not the goal of the project.

Goals:
- Have a mobile friendly UI
- Support the most common use cases (eg. finding a room)

Non Goals:
- Support every feature that the website offers (eg. showing the IP adress of the router in a room)
- Replicate the exact UI of the website
