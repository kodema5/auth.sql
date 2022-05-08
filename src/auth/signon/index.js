// @deno-types="./index.d.ts"

import { Err } from '../../core/index.js'

export let signon = async (values) => {
    // let { signon_name, signon_password } = values

    let a =  await ajax({
        url: '/api/auth/signon',
        data: values,
    })

    ajax.headers["Authorization"] = a.session_id

    // ajaxDefaults.headers["Authorization"] = a.session_id
    return a
}


signon.resolve = (values) => {
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



signon.form = {
    defaultValues: {
        signon_name: '',
        signon_password: '',
    }
}

signon.fields = {
    signon_name: {
        required: true,
        minLength: 8,
    },
    signon_password: {
        required: true,
        minLength: 8,
    },
}