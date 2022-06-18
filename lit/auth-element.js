import { Ajax, WebElement, store, pubsub } from 'https://kodema5.github.io/web-lit.js/lit.js'

import { Auth } from '../mod.js'

let STORE_ID = 'ajax.headers.Authorization'

export class AuthElement extends WebElement {

    static get properties() {
        return {
            isSigned: {type: String},
        }
    }

    constructor() {
        super()
        this.auth = new Auth({Ajax})
        let a = Ajax.ajax.headers.Authorization
        this.isSigned = !!a
    }

    async register({
        signon_name,
        signon_password
    }) {
        let a = await this.auth.register({signon_name, signon_password})
        store.set(STORE_ID, a)
        this.isSigned = !!a
        pubsub.publish('auth::change!', this.isSigned)
    }

    async signon({
        signon_name,
        signon_password
    }) {
        let a = await this.auth.signon({signon_name, signon_password})
        store.set(STORE_ID, a)
        this.isSigned = !!a
        pubsub.publish('auth::change!', this.isSigned)
    }

    async signoff() {
        if (!this.isSigned) throw new Error('unsigned')

        try {
            let a = await this.auth.signoff()
        }
        finally {
            store.set(STORE_ID, null)
            this.isSigned = false
            pubsub.publish('auth::change!', this.isSigned)
        }
    }

    connectedCallback() {
        var me = this
        super.connectedCallback()
        me.subId = pubsub.subscribe('auth::change', (isSigned) => {
            me.isSigned = isSigned
        })
    }

    disconnectedCallback() {
        var me = this
        super.disconnectedCallback()
        pubsub.unsubscribe(me.subId)

    }
}
