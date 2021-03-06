### types!
# TYPE_UNSPECIFIED	Unspecified feature type.
# FACE_DETECTION	Run face detection.
# LANDMARK_DETECTION	Run landmark detection.
# LOGO_DETECTION	Run logo detection.
# LABEL_DETECTION	Run label detection.
# TEXT_DETECTION	Run OCR.
# SAFE_SEARCH_DETECTION	Run various computer vision models to compute image safe-search properties.
# IMAGE_PROPERTIES	Compute a set of properties about the image (such as the images dominant colors).


############################################################
#' @title helper function base_encode code the image file
#' @description base64 encodes an image file
#'
#' @param imagePath provide path/url to image
#' @return get the image back as encoded file
#'
imageToText <- function(imagePath) {

  if (stringr::str_count(imagePath, "http")>0) {### its a url!
    content <- RCurl::getBinaryURL(imagePath)
    txt <- RCurl::base64Encode(content, "txt")
  } else {
    txt <- RCurl::base64Encode(readBin(imagePath, "raw", file.info(imagePath)[1, "size"]), "txt")
  }
  return(txt)
}

############################################################
#' @title helper function code to extract the response data.frame
#' @description a utility to extract features from the API response
#'
#' @param pp an API response object
#' @param feature the name of the feature to return 
#' @return a data frame
#'
extractResponse <- function(pp, feature){
  if (feature == "LABEL_DETECTION") {
    return(pp$content$responses$labelAnnotations[[1]])
  }
  if (feature == "FACE_DETECTION") {
    return(pp$content$responses$faceAnnotations[[1]])
  }
  if (feature == "LOGO_DETECTION") {
    return(pp$content$responses$logoAnnotations[[1]])
  }
  if (feature == "TEXT_DETECTION") {
    return(pp$content$responses$textAnnotations[[1]])
  }
  if (feature == "LANDMARK_DETECTION") {
    return(pp$content$responses$landmarkAnnotations[[1]])
  }
}


################## Main function: Calling the API ##################
#' @title Calling Google's Cloud Vision API
#' @description input an image, provide the feature type and maxNumber of responses
#'
#' @param imagePath path or url to the image
#' @param feature one out of: FACE_DETECTION, LANDMARK_DETECTION, LOGO_DETECTION, LABEL_DETECTION, TEXT_DETECTION
#' @param numResults the number of results to return.
#' @export
#' @return a data frame with results
#' @examples 
#' f <- system.file("exampleImages", "brandlogos.png", package = "RoogleVision")
#' getGoogleVisionResponse(imagePath = f, feature = "LOGO_DETECTION")
#' @import googleAuthR
#'
getGoogleVisionResponse <- function(imagePath, feature = "LABEL_DETECTION", numResults = 5){

  #################################
  txt <- imageToText(imagePath)
  ### create Request, following the API Docs.
  if (is.numeric(numResults)) { 
    body <- paste0('{  "requests": [    {   "image": { "content": "',txt,'" }, "features": [  { "type": "',feature,'", "maxResults": ',numResults,'} ],  }    ],}')
  } else {
    body <- paste0('{  "requests": [    {   "image": { "content": "',txt,'" }, "features": [  { "type": "',feature,'" } ],  }    ],}')
  }

  simpleCall <- gar_api_generator(baseURI = "https://vision.googleapis.com/v1/images:annotate", http_header = "POST")
  ## set the request!
  pp <- simpleCall(the_body = body)
  
  if (ncol(pp$content$responses) >0) {
    ## obtain results.
    res <- extractResponse(pp, feature)
  } else {
    res <- data.frame(error = "No features detected!")
  }

  return(res)
}

