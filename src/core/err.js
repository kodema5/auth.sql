// a simple error collector

export class Err {
    errors = {}

    add (key, msg) {
        let a = this.errors[key] =this.errors[key] || []
        a.push(msg)
        return this
    }

    has() {
        return Object.keys(this.errors).length > 0
    }
}
