// wraps fetch for simpler calls
//

export let ajaxDefaults = globalThis.ajaxDefaults || {
    CANCEL: Symbol(),
    base_href: '', // base href
    headers: {
        'Content-Type': 'application/json'
    },
}

const requestBody = (data, type) => {
    switch(type) {
        case "any": return data
        case "text": return data ? data.toString() : data
        case "json": return JSON.stringify(data)
    }

    throw new Error('unknown request data type')
}

const responseData = (res, type) => {
    if (!res.body) return null

    switch(type) {
        case 'arrayBuffer': return res.arrayBuffer()
        case 'blob': return res.blob()
        case 'formData': return res.formData()
        case 'json': return res.json()
        case 'text': return res.text()
    }

    throw new Error('unknown response type')
}

export const Ajax = ({
    url,

    input = (a) => a,
    output = (a) => a,

    headers, // to override
    body, // for FormData, URLSearchParams, string, etc
    data, // for building 'body' based on requestType
        // used in ajaxFn wrapping

    method = 'POST',
    // timeout = 0, // abort may not be supported by all platforms

    requestType = 'json', // json, text, any
    responseType = 'json', // arrayBuffer, blob, formData, json, text

} = {}) => {
    if (!url) throw new Error('missing required url')

    url = url.indexOf('http') < 0 && ajaxDefaults.base_href
        ? ajaxDefaults.base_href + url
        : url

    // validate data
    //
    try {
        data = input(data)
    } catch(e) {
        if (e === ajaxDefaults.CANCEL) return
        throw e
    }

    // build fetch options
    //
    // let signon = getStorage('auth.signon') || {}
    let fetchOpt = {
        method,
        headers: Object.assign({
            ...(ajax.headers || {}),
            ...(headers),
        }),
    }

    // fix-body
    let hasBody = !(method==='GET' || method==='HEAD')
    if (hasBody) {
        fetchOpt.body = body
            || requestBody(data || {}, requestType)
    }

    // add abort (may not be supported platforms)
    // var timedOut = false
    // let abortCtrl = new AbortController()
    // if (timeout) {
    //     setTimeout(() => {
    //         timedOut = true
    //         abortCtrl.abort()
    //     }, timeout)
    // }
    // fetchOpt.signal = abortCtrl.signal

    // fetch
    let response = fetch(url, fetchOpt)
    .then(r => {
        if (!r.ok) throw new Error('network error')
        return responseData(r, responseType)
    })
    .then(r => output(r))

    return {
        response,
        // abort: () => abortCtrl.abort(),
        // isTimedOut: () => timedOut
    }
}

const isObject = (a) => (a !== null && a instanceof Object && a.constructor === Object)


export const ajax = async (cfg) => {
    let { response } = Ajax(cfg)

    let a = await response
    if (isObject(a)) {
        let { data, errors } = a
        if (errors) throw new Error(errors)
        if (data) return data
    }
    return a
}

// creates a common ajax
//
if (!globalThis.ajax) {

    ajax.headers = ajaxDefaults.headers
    ajax.CANCEL = ajaxDefaults.CANCEL
    Object.defineProperty(ajax, 'base_href', {
        get: () => ajaxDefaults.base_href,
        set: (x) => { ajaxDefaults.base_href = x }
    })

    globalThis.ajax = ajax
}

// // wraps into a function
// //
// export const ajaxFn = (cfg) => (data) => {
//     let { response } = Ajax(Object.assign({}, cfg, {data})) || {}
//     return response
// }