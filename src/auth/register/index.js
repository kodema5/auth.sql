// @deno-types="./index.d.ts"

import { Err } from '../../core/index.js'

export let register = async (values) => {
    let a =  await ajax({
        url: '/api/auth/register',
        data: values,
    })

    ajax.headers["Authorization"] = a.session_id
    return a
}


register.resolve = (values) => {
    let err = new Err()
    let { signon_name, signon_password } = values
    if (!signon_name) {
        err.add('signon_name', 'signon_name is required')
    }
    if (!signon_password) {
        err.add('signon_password', 'signon_password is required')
    }
    if (err.has()) return { errors:err.errors }

    return { values }
}



register.form = {
    defaultValues: {
        signon_name: '',
        signon_password: '',
    }
}

register.fields = {
    signon_name: {
        required: true,
        minLength: 8,
    },
    signon_password: {
        required: true,
        minLength: 8,
    },
}