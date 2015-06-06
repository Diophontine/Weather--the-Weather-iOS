//
//  Protocal.swift
//  Weather the Weather
//
//  Created by DD Bobs on 2015-06-05.
//  Copyright (c) 2015 Diophontine. All rights reserved.
//

import Foundation
//pop the search controller and get the data back
protocol returnSearchLocationDelegate {
   func getSearchResult(location: NSDictionary)
}