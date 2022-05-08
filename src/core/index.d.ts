declare global {

    function ajax(v:any): Promise<any>;

    namespace ajax {
        var base_href:string // <blank>
        let headers:any      // content-type: application/json
    }
}