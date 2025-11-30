import requests
import json
import time

# Base URL for the API
url = "http://localhost:8001/chat"

english_queries = [
    "What is the punishment for theft?",
    "What is the punishment for murder?",
    "What happens if someone steals property?",
    "What is the Dowry Prohibition Act?",
    "What is the punishment for rape?",
    "How are witness statements recorded?",
    "What is the age of consent for marriage?",
    "What are the penalties for domestic violence?",
    "How is evidence collected in criminal cases?",
    "What is the punishment for drug trafficking?",
    "What are the rights of an accused person?",
    "What is the procedure for filing a police complaint?",
    "What is the punishment for corruption?",
    "How are juvenile offenders treated?",
    "What is the punishment for cybercrime?",
    "What are the provisions for bail?",
    "What is the punishment for kidnapping?",
    "How is a FIR registered?",
    "What are the penalties for environmental crimes?",
    "What is the punishment for human trafficking?",
    "How are court judgments appealed?"
]

# Hindi queries (20 questions)
hindi_queries = [
    "हत्या के लिए क्या सजा है?",
    "चोरी करने पर क्या होता है?",
    "दहेज प्रतिषेध अधिनियम क्या है?",
    "बलात्कार के मामले में कितनी सजा होती है?",
    "गवाहों के बयान कैसे दर्ज होते हैं?",
    "विवाह के लिए सहमति की आयु क्या है?",
    "घरेलू हिंसा के लिए क्या दंड हैं?",
    "आपराधिक मामलों में सबूत कैसे एकत्र किए जाते हैं?",
    "नशीली दवाओं की तस्करी के लिए क्या सजा है?",
    "आरोपी व्यक्ति के क्या अधिकार हैं?",
    "पुलिस शिकायत दर्ज करने की प्रक्रिया क्या है?",
    "भ्रष्टाचार के लिए क्या सजा है?",
    "किशोर अपराधियों का कैसे इलाज किया जाता है?",
    "साइबर अपराध के लिए क्या सजा है?",
    "जमानत के लिए क्या प्रावधान हैं?",
    "अपहरण के लिए क्या सजा है?",
    "एफआईआर कैसे दर्ज की जाती है?",
    "पर्यावरण अपराधों के लिए क्या दंड हैं?",
    "मानव तस्करी के लिए क्या सजा है?",
    "न्यायालय के निर्णयों को कैसे अपील की जाती है?"
]

# Nepali queries (20 questions)
nepali_queries = [
    "हत्याको लागि के सजाय छ?",
    "चोरी गर्नु परे के हुन्छ?",
    "दाइजो निषेध ऐन के हो?",
    "बलात्कारको मामिलामा कति सजाय हुन्छ?",
    "साक्षीहरूका बयानहरू कसरी रेकर्ड गरिन्छ?",
    "विवाहको लागि सहमतिका उमेर के हो?",
    "घरेलु हिंसाका लागि के दण्डहरू छन्?",
    "आपराधिक मामिलाहरूमा प्रमाणहरू कसरी संकलन गरिन्छ?",
    "नशीली औषधिहरूको तस्करीका लागि के सजाय छ?",
    "आरोपी व्यक्तिका के अधिकारहरू छन्?",
    "प्रहरी उजुरी दर्ता गर्ने प्रक्रिया के हो?",
    "भ्रष्टाचारका लागि के सजाय छ?",
    "किशोर अपराधीहरूलाई कसरी व्यवहार गरिन्छ?",
    "साइबर अपराधका लागि के सजाय छ?",
    "जमानतका लागि के प्रावधानहरू छन्?",
    "अपहरणका लागि के सजाय छ?",
    "एफआईआर कसरी दर्ता गरिन्छ?",
    "पर्यावरण अपराधहरूका लागि के दण्डहरू छन्?",
    "मानव तस्करीका लागि के सजाय छ?",
    "न्यायालयका निर्णयहरूलाई कसरी अपिल गरिन्छ?"
]


# English queries (20 questions)
english_queries = [
    "What is the punishment for murder in BNS?",
    "What is the punishment for culpable homicide?",
    "What is the punishment for attempt to murder?",
    "What is the punishment for rash act?",
    "What is the punishment for causing death by rash act?",
    "What is the punishment for dowry death?",
    "What is the punishment for abetment of suicide?",
    "What is the punishment for attempt to suicide?",
    "What is the punishment for hurt?",
    "What is the punishment for grievous hurt?",
    "What is the punishment for theft in BNS?",
    "What is the punishment for robbery?",
    "What is the punishment for dacoity?",
    "What is the punishment for blackmail?",
    "What is the punishment for cheating?",
    "What is the punishment for forgery?",
    "What is the punishment for defamation?",
    "What is the punishment for assault?",
    "What is the punishment for kidnapping?",
    "What is the punishment for human trafficking?"
]

# Hindi queries (20 questions)
hindi_queries = [
    "BNS में हत्या की सजा?",
    "दोषपूर्ण हत्या की सजा?",
    "हत्या के प्रयास की सजा?",
    "अविवेकपूर्ण कार्य की सजा?",
    "अविवेकपूर्ण कार्य से मृत्यु की सजा?",
    "दहेज मृत्यु की सजा?",
    "आत्महत्या उकसाने की सजा?",
    "आत्महत्या के प्रयास की सजा?",
    "चोट की सजा?",
    "गंभीर चोट की सजा?",
    "BNS में चोरी की सजा?",
    "लूट की सजा?",
    "डकैती की सजा?",
    "ब्लैकमेल की सजा?",
    "धोखाधड़ी की सजा?",
    "जालसाजी की सजा?",
    "मानहानि की सजा?",
    "हमले की सजा?",
    "अपहरण की सजा?",
    "मानव तस्करी की सजा?"
]

# Nepali queries (20 questions)
nepali_queries = [
    "BNS मा हत्याको सजाय?",
    "दोषपूर्ण हत्याको सजाय?",
    "हत्या प्रयासको सजाय?",
    "अविवेकपूर्ण कार्यको सजाय?",
    "अविवेकपूर्ण कार्यबाट मृत्युको सजाय?",
    "दाइजो मृत्युको सजाय?",
    "आत्महत्या उक्साउने सजाय?",
    "आत्महत्या प्रयासको सजाय?",
    "चोटको सजाय?",
    "गम्भीर चोटको सजाय?",
    "BNS मा चोरीको सजाय?",
    "लुटको सजाय?",
    "डकैतीको सजाय?",
    "ब्ल्याकमेलको सजाय?",
    "धोखाको सजाय?",
    "जालसाजीको सजाय?",
    "मानहानिको सजाय?",
    "हमलाको सजाय?",
    "अपहरणको सजाय?",
    "मानव तस्करीको सजाय?"
]

def test_query(query, language, results_list):
    data = {
        "query": query,
        "language": language
    }
    start_time = time.time()
    try:
        response = requests.post(url, json=data, timeout=30)
        end_time = time.time()
        response_time = end_time - start_time

        print(f"\n--- {language.upper()} Query: {query} ---")
        print("Status Code:", response.status_code)
        print(".2f")
        if response.status_code == 200:
            resp_data = response.json()
            print("Language:", resp_data.get('language'))
            print("Title:", resp_data.get('title'))
            print("Source Code:", resp_data.get('source_code'))
            print("Source Name:", resp_data.get('source_name'))
            print("Explanation (first 100 chars):", resp_data.get('explanation')[:100] + "...")

            # Store result for accuracy evaluation
            result = {
                "query": query,
                "language": language,
                "status_code": response.status_code,
                "response_time": response_time,
                "title": resp_data.get('title'),
                "source_code": resp_data.get('source_code'),
                "source_name": resp_data.get('source_name'),
                "explanation": resp_data.get('explanation'),
                "penalties": resp_data.get('penalties', []),
                "references": resp_data.get('references', [])
            }
            results_list.append(result)
        else:
            print("Error:", response.text)
            results_list.append({
                "query": query,
                "language": language,
                "status_code": response.status_code,
                "response_time": response_time,
                "error": response.text
            })
    except requests.exceptions.RequestException as e:
        end_time = time.time()
        response_time = end_time - start_time
        print(f"Request failed for query '{query}': {e}")
        results_list.append({
            "query": query,
            "language": language,
            "response_time": response_time,
            "error": str(e)
        })

def evaluate_accuracy(results, language_name):
    total_queries = len(results)
    successful_responses = sum(1 for r in results if r.get('status_code') == 200)
    success_rate = (successful_responses / total_queries) * 100 if total_queries > 0 else 0

    # Response time statistics
    response_times = [r.get('response_time', 0) for r in results if r.get('response_time') is not None]
    avg_response_time = sum(response_times) / len(response_times) if response_times else 0
    min_response_time = min(response_times) if response_times else 0
    max_response_time = max(response_times) if response_times else 0

    # Basic accuracy metrics
    has_title = sum(1 for r in results if r.get('title') and r.get('title') != "")
    has_source = sum(1 for r in results if r.get('source_code') in ['BNS', 'BSA', 'BNSS'])
    has_explanation = sum(1 for r in results if r.get('explanation') and len(r.get('explanation', '')) > 50)

    # Manual accuracy assessment (this would need human evaluation for true accuracy)
    # For now, we'll assume all successful responses are accurate since we can't manually verify each one
    accurate_responses = successful_responses  # Placeholder - would need manual verification

    print(f"\n{'='*60}")
    print(f"ACCURACY EVALUATION FOR {language_name.upper()}")
    print(f"{'='*60}")
    print(f"Total Queries: {total_queries}")
    print(f"Successful Responses (200): {successful_responses} ({success_rate:.1f}%)")
    print(f"Queries with Title: {has_title}")
    print(f"Queries with Valid Source (BNS/BSA/BNSS): {has_source}")
    print(f"Queries with Substantial Explanation (>50 chars): {has_explanation}")
    print(f"Response Time - Average: {avg_response_time:.2f}s, Min: {min_response_time:.2f}s, Max: {max_response_time:.2f}s")

    # Note about manual accuracy assessment
    print(f"\nNOTE: Accuracy assessment requires manual verification of each response.")
    print(f"Assuming all successful responses are accurate for calculation purposes.")
    print(f"Manual accuracy would need human review of {successful_responses} responses.")

    # Save detailed results to file
    #filename = f"evaluation_results_{language_name.lower()}.json"
    #   json.dump(results, f, ensure_ascii=False, indent=2)
    #print(f"Detailed results saved to {filename}")

if __name__ == "__main__":
    # Test English queries
    print("Testing English queries...")
    english_results = []
    for query in english_queries:
        test_query(query, "en", english_results)

    # Test Hindi queries
    print("\n" + "="*50)
    print("Testing Hindi queries...")
    hindi_results = []
    for query in hindi_queries:
        test_query(query, "hi", hindi_results)

    # Test Nepali queries
    print("\n" + "="*50)
    print("Testing Nepali queries...")
    nepali_results = []
    for query in nepali_queries:
        test_query(query, "ne", nepali_results)

    # Evaluate accuracy for each language
    evaluate_accuracy(english_results, "English")
    evaluate_accuracy(hindi_results, "Hindi")
    evaluate_accuracy(nepali_results, "Nepali")

    print(f"\n{'='*60}")
    print("OVERALL SUMMARY")
    print(f"{'='*60}")
    total_all = len(english_results) + len(hindi_results) + len(nepali_results)
    success_all = sum(1 for r in english_results + hindi_results + nepali_results if r.get('status_code') == 200)
    overall_rate = (success_all / total_all) * 100 if total_all > 0 else 0

    # Overall response time statistics
    all_response_times = []
    for results in [english_results, hindi_results, nepali_results]:
        all_response_times.extend([r.get('response_time', 0) for r in results if r.get('response_time') is not None])

    overall_avg_time = sum(all_response_times) / len(all_response_times) if all_response_times else 0

    print(f"Total Queries Across All Languages: {total_all}")
    print(f"Overall Success Rate: {overall_rate:.1f}%")
    print(".2f")
