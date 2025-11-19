module Main exposing (main)

import Browser
import Message exposing (Msg)
import Types exposing (Model)
import Update exposing (init, subscriptions, update)
import View exposing (view)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
