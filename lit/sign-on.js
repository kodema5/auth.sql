// an example sign-on component
//
import { html } from 'https://kodema5.github.io/web-lit.js/lit.js'
import { AuthElement } from './auth-element.js'

export class SignOn extends AuthElement {

    static get properties() {
        return {
            signon_name: { type:String },
            signon_password: { type:String },
            error: { type:String },
        }
    }

    reset () {
        this.signon_name = ''
        this.signon_password = ''
        this.error = ''
    }

    render () {
        let me = this
        if (me.isSigned) return null

        return html`
        <form>
        <div class="mb-3">
            <label
                for="signon_name"
                class="form-label">Name</label>
            <input
                type="email"
                class="form-control"
                id="signon_name"
                value=${me.signon_name}
                @change=${(e) => {
                    me.signon_name=e.target.value
                }}
            >
        </div>
        <div class="mb-3">
            <label
                for="signon_password"
                class="form-label">Password</label>
            <input
                type="password"
                class="form-control"
                id="signon_password"
                value=${me.signon_password}
                @change=${(e) => {
                    me.signon_password=e.target.value
                }}
            >
        </div>

        ${ me.error && html`
            <div class="alert alert-danger mb-3">
            ${me.error}
            </div>
        `}
        <div class="text-end">
        <button type="button"
            class="btn btn-link"
            @click=${async () => {
                try {
                    await me.register({
                        signon_name: me.signon_name,
                        signon_password: me.signon_password,
                    })
                    setTimeout(() => {
                        me.reset()
                    })
                } catch(e) {
                    me.error = e
                }
            }}
        >Register</button>
        <button type="button"
            class="btn btn-primary"
            @click=${async () => {
                try {
                    await me.signon({
                        signon_name: me.signon_name,
                        signon_password: me.signon_password,
                    })
                    setTimeout(() => {
                        me.reset()
                    })
                } catch(e) {
                    me.error = e
                }
            }}
        >Sign In</button>
        <div>

        </form>
        `
    }
}