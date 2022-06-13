// @deno-types="./index.d.ts"

import { register } from './register/index.js'
import { signon } from './signon/index.js'
import { signoff } from './signoff/index.js'

export class Auth {
    constructor ({Ajax}) {
        this.Ajax = Ajax
        this.ajax = Ajax.ajax
    }
}

Object.assign(Auth.prototype, {
    register,
    signon,
    signoff,
})

