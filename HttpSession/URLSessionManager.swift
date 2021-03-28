//
//  URLSessionManager.swift
//  HttpSession
//
//  Created by keisuke yamagishi on 2021/03/01.
//

import Foundation

class URLSessionManager: NSObject {
    /*
     * Callback function
     * success Handler
     *
     */
    typealias CompletionHandler = (Data?, HTTPURLResponse?, Error?) -> Void
    typealias ProgressHandler = (_ written: Int64, _ total: Int64, _ expectedToWrite: Int64) -> Void
    typealias DownloadHandler = (_ path: URL?) -> Void

    var progressHandler: ProgressHandler?
    var completionHandler: CompletionHandler?
    var downloadHandler: DownloadHandler?

    var response: HTTPURLResponse?
    var dataTask: URLSessionDataTask?
    var downloadTask: URLSessionDownloadTask?
    var request: Request?
    var data: Data?
    var isCookie: Bool = false
    var sessionConfig: URLSessionConfiguration?
    var session: URLSession?

    func request(url: String,
                 method: Http.Method = .get,
                 isNeedDefaultHeader: Bool = true,
                 header: [String: String]? = nil,
                 params: [String: String]? = nil,
                 multipart: [Multipartible]? = nil,
                 cookie: Bool = false,
                 basic: [String: String]? = nil)
    {
        data = nil
        isCookie = cookie
        request = Request(url: url,
                          method: method,
                          isNeedDefaultHeader: isNeedDefaultHeader,
                          headers: header,
                          parameter: params,
                          multipart: multipart,
                          cookie: cookie,
                          basic: basic)
    }

    public func session(completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        completionHandler = completion
        guard let request = request?.urlRequest else {
            return
        }
        send(request: request)
    }

    public func download(resumeData: Data? = nil,
                         progress: @escaping (_ written: Int64, _ total: Int64, _ expectedToWrite: Int64) -> Void,
                         download: @escaping (_ path: URL?) -> Void,
                         completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
    {
        /*
         /_/_/_/_/_/_/_/_/_/_/_/_/_/_/

         Resume data handling

         /_/_/_/_/_/_/_/_/_/_/_/_/_/_/
         */
        if resumeData == nil {
            progressHandler = progress
            completionHandler = completion
            downloadHandler = download
            sessionConfig = URLSessionConfiguration.background(withIdentifier: "httpSession-background")
            session = URLSession(configuration: sessionConfig!, delegate: self, delegateQueue: .main)

            guard let urlRequest = request?.urlRequest else {
                return
            }

            downloadTask = session?.downloadTask(with: urlRequest)
        } else {
            downloadTask = session?.downloadTask(withResumeData: resumeData!)
        }
        downloadTask?.resume()
    }

    public func cancel(byResumeData: @escaping (Data?) -> Void) {
        downloadTask?.cancel { data in
            byResumeData(data)
        }
    }

    public func cancel() {
        dataTask?.cancel()
    }

    public func upload(progress: ((_ written: Int64, _ total: Int64, _ expectedToWrite: Int64) -> Void)? = nil,
                       completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        progressHandler = progress
        completionHandler = completion
        guard let urlRequest = request?.urlRequest else { return }
        send(request: urlRequest)
    }

    /*
     * send Request
     */
    private func send(request: URLRequest) {
        if sessionConfig == nil {
            sessionConfig = URLSessionConfiguration.default
        }
        let session = URLSession(configuration: sessionConfig!, delegate: self, delegateQueue: .main)
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
    }
}

extension URLSessionManager: URLSessionDataDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    public func urlSession(_: URLSession,
                           downloadTask _: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL)
    {
        downloadHandler?(location)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        progressHandler?(bytesSent, totalBytesSent, totalBytesExpectedToSend)
    }
    
    public func urlSession(_: URLSession,
                           downloadTask _: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64)
    {
        progressHandler?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    /*
     * Get Responce and Result
     *
     *
     */
    public func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        if isCookie {
            isCookie = false
            if let unwrapResponce = response {
                Cookie.shared.set(unwrapResponce)
            }
        }
        completionHandler?(data, response, error)
    }

    /*
     * get recive function
     *
     */
    public func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        recivedData(data)
    }

    /*
     * get Http response
     *
     */
    public func urlSession(_: URLSession,
                           dataTask _: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        self.response = response as? HTTPURLResponse
        completionHandler(.allow)
    }

    func recivedData(_ data: Data) {
        if self.data == nil {
            self.data = data
        } else {
            self.data?.append(data)
        }
    }
}
