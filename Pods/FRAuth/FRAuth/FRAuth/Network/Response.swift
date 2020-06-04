//
//  Response.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// This struct is a representation of FRAuth's API request response data structure, and is responsible to handle response serialization
struct Response {
    
    /// response Data
    let data: Data?
    /// URLResponse object containing HTTP information of the response
    let response: URLResponse?
    /// API request failure error
    let error: Error?
    
    /// Parses response into Result object
    ///
    /// - Returns: Result object notifying whether the request was successful, or failed with an error
    func parseReponse() -> Result {
        //  Make sure the response data is returned, HTTP response status code is within successful range, and error is nil
        guard let responseData = self.data, let httpresponse = self.response as? HTTPURLResponse, (200 ..< 303) ~= httpresponse.statusCode, self.error == nil else {
            return Result.failure(error: AuthError.converToAuthError(data: self.data, response: self.response, error: self.error))
        }
        if responseData.isEmpty {
            return Result.success(result: [:], httpResponse: self.response)
        }
        else {
            //  TODO: Response handling as per Accept header
            if let jsonData = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String:AnyObject] {
                return Result.success(result: jsonData, httpResponse: self.response)
            }
            else {
                return Result.failure(error: AuthError.invalidResponseDataType)
            }
        }
    }
}
